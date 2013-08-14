module Spree
  module Jobs

    Options ||= Struct.new :options
    class GenerateCsv < Options 

      def perform
        csv_instance = options[:csv_instance]
        begin
          csv_instance.write_csv( options[:params] )
        ensure
          # This is a race condition, as this could be called then the pid could get set
          csv_instance.update_attribute(:job_id, nil)
        end
      end

    end
  end
end 
