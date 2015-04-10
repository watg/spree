module Spree
  module Jobs

    Options ||= Struct.new :options
    class GenerateCsv < Options 

      def perform
        report_instance = options[:report_instance]
        begin
          report_instance.write_csv(options[:name], options[:klass], options[:params])
        rescue => e
          puts "#{e.to_s}\n #{e.backtrace}"
          Rails.logger.error("#{e.to_s}\n #{e.backtrace}")
        ensure
          report_instance.update_attribute(:job_id, report_instance.finished_status)
        end
      end

    end
  end
end 
