module Spree
  class Report < ActiveRecord::Base
    attr_accessible :job_id, :filename, :file_id, :download_uri

    DEFAULT_REPORTS_FOLDER_ID = '0B9oajy9I3FKQNjRwRkh4Ml9XUVk'
    PRODUCTION_REPORTS_FOLDER_ID = '0B9oajy9I3FKQOTE3bnE4OFh4ZmM'
    FINISHED = -1

    def finished_status
      FINISHED 
    end

    def reports_folder_id
      if Rails.env.production?
        PRODUCTION_REPORTS_FOLDER_ID
      else
        DEFAULT_REPORTS_FOLDER_ID
      end
    end

    def finished?
      job_id == FINISHED 
    end

    def generating?
      job_id > 0
    end

    def trigger_csv_generation(name, params)
      params ||= {}
      csv = Spree::Jobs::GenerateCsv.new({:report_instance => self, :name => name, :params => params})
      job = Delayed::Job.enqueue csv 
      self.update_attributes(job_id: job.id)
    end

    # TODO: this needs to go into a singleton
    # 2. base class for other reports
    # 4. Tests

    def write_csv(name, params)
      report = get_report_instance(name, params)

      csv_string = CSV.generate do |csv|
        csv << report.header
        report.retrieve_data do |data| 
          csv << data
        end
      end

      gfile = GoogleDriveStorage.upload_csv_string( csv_string, report.filename, true )
      gfile.parent_directory( reports_folder_id )
      gfile.add_permission( 'reports@woolandthegang.com', 'group', 'reader' )
      self.update_attributes( file_id: gfile.file_id, download_uri: gfile.download_uri, filename: gfile.converted_filename )
      self.save!
    end

    def data
      GoogleDriveStorage.download_data( self.download_uri )
    end

    protected

    def get_report_instance(name, params)
      klass = "Spree::#{name.camelize}Report".constantize
      klass.new(params)
    end
  end
end
