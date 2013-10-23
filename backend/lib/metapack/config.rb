module Metapack
  class Config
    class << self
      def config
        @config ||= load_config
      end
      
      def load_config
        YAML::load_file(File.join(Rails.root, "config", "metapack.yml"))[Rails.env]
      end
      
      def host
        config["host"]
      end

      def service_base_url
        config["service_base_url"]
      end

      def username
        ENV["METAPACK_USERNAME"] || config["username"]
      end

      def password
        ENV["METAPACK_PASSWORD"] || config["password"]
      end
      
      def active
        if ENV["METAPACK_ACTIVE"].nil?
          config["active"]
        else
          bool(ENV["METAPACK_ACTIVE"])
        end
      end

      private
      def bool(str)
        str == "true"
      end
    end
    
  end
end
