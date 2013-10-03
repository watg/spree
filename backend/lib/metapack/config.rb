module Metapack
  class Config
    def self.config
      @config ||= load_config
    end

    def self.load_config
      YAML::load_file(File.join(Rails.root, "config", "metapack.yml"))[Rails.env]
    end

    def self.host
      self.config["host"]
    end

    def self.service_base_url
      self.config["service_base_url"]
    end

    def self.username
      ENV["METAPACK_USERNAME"] || self.config["username"]
    end

    def self.password
      ENV["METAPACK_PASSWORD"] || self.config["password"]
    end
  end
end
