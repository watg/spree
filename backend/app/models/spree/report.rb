module Spree
  class Report < ActiveRecord::Base
    attr_accessible :job_id, :filename

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

    def trigger_csv_generation(name, params)
      params ||= {}
      csv = Spree::Jobs::GenerateCsv.new({:report_instance => self, :name => name, :params => params})
      job = Delayed::Job.enqueue csv 
      job_id = job.id
    end

    def write_csv(name, params)
      report = get_report_instance(name, params)

      Tempfile.open([self.filename, '.csv']) do |fh|
        begin
          csv = CSV.new(fh)
          csv << report.header
          report.retrieve_data do |data| 
            csv << data
          end
          fh.flush
          self.filename = fh.path
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

    def get_report_instance(name, params)
      klass = "Spree::#{name.camelize}Report".constantize
      klass.new(params)
    end

    def data_string
      raise "override me"
    end
  end
end
