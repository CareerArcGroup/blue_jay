# frozen_string_literal: true

require 'blue_jay'
require 'pry'

module SpecHelper
  class Config
    attr_reader :client, :disconnected_client, :unauthorized_client

    def initialize(klass)
      @klass = klass

      initialize_config

      logger = Logger.new(STDERR)
      logger.level = Logger::DEBUG

      BlueJay.logger = logger
      # BlueJay.trace!

      options = {}
      options_with_credentials = options.merge(credentials)

      puts "Opts with creds: #{options_with_credentials}"

      @client = klass.new(options_with_credentials)
      @disconnected_client = klass.new(options_with_credentials.merge(proxy: 'localhost'))
      @unauthorized_client = klass.new(options)
    end

    def consumer_key
      credentials['consumer_key']
    end

    def consumer_secret
      credentials['consumer_secret']
    end

    def token
      credentials['token']
    end

    def secret
      credentials['secret']
    end

    def credentials
      @config[platform]['credentials'].inject({}) { |memo, (k, v)| memo.update(k.to_sym => v) }
    end

    def settings
      @config[platform]['settings']
    end

    private

    def initialize_config
      # get the Twitter credentials from a file.
      # if the file is missing, alert the user...
      config_file_path = File.expand_path('spec_config.yml', __dir__)

      raise <<~ERROR unless File.exist?(config_file_path)
        Please rename spec/spec_config.yml.sample
        to spec_config.yml and provide your various API
        credentials and test settings for use in these tests.
      ERROR

      @config = YAML.safe_load(File.read(config_file_path))
    end

    def platform
      @klass.name.downcase.gsub(/client/, '').split('::').last
    end
  end
end
