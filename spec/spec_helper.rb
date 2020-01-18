
require 'blue_jay'
require 'pry'

module SpecHelper
  class Config
    attr_reader :client, :disconnected_client, :unauthorized_client

    def initialize(klass)
      @klass = klass

      # get the Twitter credentials from a file.
      # if the file is missing, alert the user...
      config_file_path = File.expand_path("../spec_config.yml", __FILE__)

      unless File.exists? config_file_path
        raise "Please rename spec/spec_config.yml.sample " +
          "to spec_config.yml and provide your various API" +
          "credentials and test settings for use in these tests."
      end

      @config = YAML::load(File.read(config_file_path))

      logger = Logger.new(STDERR)
      logger.level = Logger::DEBUG
      #logger.formatter = BlueJay::Logging::GelfFormatter.new

      BlueJay.logger = logger
      #BlueJay.trace!

      options = { }
      options_with_credentials = options.merge(
        consumer_key: consumer_key,
        consumer_secret: consumer_secret,
        token: token,
        secret: secret
      )

      @client = klass.new(options_with_credentials)
      @disconnected_client = klass.new(options_with_credentials.merge(:proxy => "localhost"))
      @unauthorized_client = klass.new(options)
    end

    def consumer_key
      @config[platform]["credentials"]["consumer_key"]
    end

    def consumer_secret
      @config[platform]["credentials"]["consumer_secret"]
    end

    def token
      @config[platform]["credentials"]["token"]
    end

    def secret
      @config[platform]["credentials"]["secret"]
    end

    def settings
      @config[platform]["settings"]
    end

    private

    def platform
      @klass.name.downcase.gsub(/client/, "").split("::").last
    end
  end
end