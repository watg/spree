module Spree
  module Jobs

    Options ||= Struct.new :options
    class GenerateCsv < Options 


      def perform
        csv_instance = options[:csv_instance]
        begin
          csv_instance.write_csv( options[:params] )
        ensure
          csv_instance.update_attribute(:job_id, csv_instance.finished_status)
        end
      end

    end
  end
end 
