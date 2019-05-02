
require 'oauth'
require 'json'
require 'logger'
require 'blue_jay/version'
require 'blue_jay/mime'
require 'blue_jay/util'
require 'blue_jay/trace'

require 'blue_jay/logging/http_logger'
require 'blue_jay/logging/gelf_formatter'

require 'blue_jay/client'
require 'blue_jay/clients/oauth_client'
require 'blue_jay/clients/oauth2_client'
require 'blue_jay/clients/twitter_client'
require 'blue_jay/clients/twitter_enterprise_client'
require 'blue_jay/clients/linked_in_client'
require 'blue_jay/clients/linked_in_client_v1'
require 'blue_jay/clients/linked_in_client_v2'
require 'blue_jay/clients/facebook_client'
require 'blue_jay/clients/slack_client'
require 'blue_jay/clients/instagram_client'

require 'blue_jay/parser'
require 'blue_jay/parsers/twitter_parser'
require 'blue_jay/parsers/linked_in_parser'
require 'blue_jay/parsers/facebook_parser'
require 'blue_jay/parsers/slack_parser'
require 'blue_jay/parsers/instagram_parser'
require 'blue_jay/parsers/twitter_enterprise_parser'

module BlueJay
  extend self

  def logger=(logger)
    @logger = logger
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def trace?
    @trace
  end

  def trace!
    @trace = true
  end
end
