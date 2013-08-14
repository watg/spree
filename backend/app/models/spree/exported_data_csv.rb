module Spree
  class ExportedDataCsv < ActiveRecord::Base
    #acts_as_singleton
    attr_accessor :search
    attr_accessible :search

    BUCKET = 'reports'
    has_attached_file :csv_file

    include Spree::Core::S3Support
    supports_s3 :csv_file

    #self.attachment_definitions[:csv_file][:default_url]    = '/spree/products/:id/:style/:basename.:extension' 
    self.attachment_definitions[:csv_file][:s3_protocol]    = 'https'
    self.attachment_definitions[:csv_file][:s3_permissions] = "authenticated_read",
    self.attachment_definitions[:csv_file][:s3_host_name]   = "s3-eu-west-1.amazonaws.com"
    self.attachment_definitions[:csv_file][:bucket]         = BUCKET 

    def generating?
      job_id.present?
    end

    def csv_file_exists?
      !self.csv_file_file_name.blank?
    end

    def trigger_csv_generation( params )
      if valid_params( params )
        csv = Spree::Jobs::GenerateCsv.new({:csv_instance => self, :params => params})
        job = Delayed::Job.enqueue csv 
        update_attribute(:job_id, job.id)
      else
        # TODO: callback that params were invalid
      end
    end

    def write_csv( params )
      Tempfile.open([self.filename, '.csv']) do |fh|
        begin
          csv = CSV.new(fh)
          csv << header
          retrieve_data(params) do |data| 
            csv << data
          end
          fh.flush
          self.csv_file = fh
          self.save!
        ensure
          fh.close
          fh.unlink # deletes the temp file
        end
      end
    end

    def name
      self.class.to_s.split('::').last.underscore
    end
    
    protected
    def valid_params( params )
      true
    end

    # Kevin says: override me in subclasses ...
    def filename
      'exported_data_csv_'
    end

    def data_string
      ''
    end
  end
end
