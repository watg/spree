module Spree
  class ExportedDataCsv < ActiveRecord::Base

    FINISHED = -1

    def finished_status
      FINISHED 
    end

    def finished?
      job_id == FINISHED 
    end

    def generating?
      job_id > 0
    end

    def trigger_csv_generation( params={} )
      csv = Spree::Jobs::GenerateCsv.new({:csv_instance => self, :params => params})
      job = Delayed::Job.enqueue csv 
      job_id = job.id
    end

    def write_csv( params={} )
      Tempfile.open([self.filename, '.csv']) do |fh|
        begin
          csv = CSV.new(fh)
          csv << header
          retrieve_data(params) do |data| 
            csv << data
          end
          fh.flush
          self.csv_file_file_name = fh.path
          self.save!
        ensure
          fh.close
        end
      end
    end

    def name
      self.class.to_s.split('::').last.underscore
    end
    
    protected

    def filename
      raise "override me"
    end

    def data_string
      raise "override me"
    end
  end
end
