require 'google/api_client'
module GoogleStorage



  class << self

    # The connection object is responsible for talking to google.
    attr_accessor :connection

    # A GoogleStorage configuration object. Must act like a hash and return sensible
    # values for all Airbrake configuration options.
    attr_writer :configuration

    # Call this method to modify defaults in your initializers.
    #
    # @example
    #   GoogleStorage.configure do |config|
    #     config.client_email  = '1234567890abcdef'
    #     config.client_secret = '1234567890abcdef'
    #     config.private_key   = '1234567890abcdef'
    #   end
    def configure
      yield(configuration)
    end

    # The configuration object.
    def configuration
      puts "BEGIN XXXXXXXXXXXXXXXXXXXXXXXXXXX"
      puts @configuration.object_id
      @configuration ||= Configuration.new
      puts "AFTER XXXXXXXXXXXXXXXXXXXXXXXXXXX"
      puts @configuration.object_id
      @configuration
    end

    def upload_csv_string(string, filename, convert=false)
      connection = Connection.new(configuration)
      if convert == true
        SpreadSheet.upload_csv_string(connection, string, filename)
      else
        File.upload_csv_string(connection, string, filename)
      end
    end 

    def download_data( uri )
      connection = Connection.new(configuration)
      connection.client.execute(:uri => uri).body
    end

  end

  class Configuration

    OPTIONS = [:client_email, :client_secret, :private_key].freeze

    attr_accessor :client_email
    attr_accessor :client_secret
    attr_accessor :private_key

    def initialize
      @client_email  #||= ENV['GOOGLE_STORAGE_CLIENT_EMAIL']
      @client_secret #||= ENV['GOOGLE_STORAGE_CLIENT_SECRET'] 
      @private_key   #||= ENV['GOOGLE_STORAGE_CLIENT_PRIVATE_KEY']
    end

    # Returns a hash of all configurable options
    def to_hash
      OPTIONS.inject({}) do |hash, option|
        hash[option.to_sym] = self.send(option)
        hash
      end
    end

  end

  class Connection

    attr_accessor :client
    attr_accessor :drive

    def initialize(config)
      @client = init_client( config )
      @drive = @client.discovered_api('drive', 'v2')
    end

    private
    def init_client( config )
      client = Google::APIClient.new( application_name: 'ecom_site', application_version: '1' )  
      key = OpenSSL::PKey::RSA.new(config.private_key, config.client_secret)

      service_account = Google::APIClient::JWTAsserter.new(
        config.client_email,
        'https://www.googleapis.com/auth/drive.file',
        key)

      client.authorization = service_account.authorize
      client
    end

  end

  class File

    attr_accessor :download_url, :filename
    #attr_accessor :filename_prefix
    #attr_accessor :filename_suffix

    def initialize(connection,google_file,filename)
      @connection = connection
      @google_file = google_file
      @filename = filename

      # spit up the filename
      @filename =~ /^(.*)\.(\w+)$/
      @filename_prefix = $1 
      @filename_suffix = $2 
    end

    def self.upload_csv_string(connection, data, filename, convert=false)
      media = Google::APIClient::UploadIO.new(StringIO.new(data), 'text/csv', filename)
      metadata = {
        'title' => filename,
        'description' => 'tbd',
        'mimeType' => 'text/csv',
      }

      google_file = connection.client.execute(
        :api_method => connection.drive.files.insert,
        :parameters => { 'uploadType' => 'multipart', 'convert' => convert },
        :body_object => metadata,
        :media => media )

      self.new(connection,google_file,filename)
    end

    def parent_directory( parent_id )
      new_parent = @connection.drive.parents.insert.request_schema.new({
        'id' => parent_id
      })

      result = @connection.client.execute(
        :api_method => @connection.drive.parents.insert,
        :body_object => new_parent,
        :parameters => { 'fileId' => @google_file.data.id })
    end

      #result = client.execute(:uri => foo.data.exportLinks["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"])

    def add_permission( value, type, role )
      new_permission = @connection.drive.permissions.insert.request_schema.new({
        'value' => value,  # 'reports@woolandthegang.com',
        'type'  => type,   # 'group',
        'role'  => role,   #'reader' 
      })

      result = @connection.client.execute(
        :api_method => @connection.drive.permissions.insert,
        :body_object => new_permission,
        :parameters => { 'fileId' => @google_file.data.id })
    end

    def download_uri
      @google_file.data.download_url
    end

    def download_data
      self.class.download_data( @connection, download_uri )
    end

    def self.download_data( connection, uri )
      connection.client.execute(:uri => uri).body
    end

    def file_id
      @google_file.data.id
    end

    def converted_filename
      "#{filename_prefix}.#{filename_suffix}"
    end


    private
    def filename_prefix
      @filename_prefix
    end

    def filename_suffix
      @filename_suffix
    end
  end


  class SpreadSheet < File

    def self.upload_csv_string(connection, data, filename)
      super(connection, data, filename, true)
    end

    def download_uri
      @google_file.data.exportLinks["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]
    end

    private
    def filename_suffix
      'xlsx'
    end

  end
end


