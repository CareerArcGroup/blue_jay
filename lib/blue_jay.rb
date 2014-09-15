
module BlueJay
end

require 'oauth'
require 'json'
require 'blue_jay/version'

require 'blue_jay/client'
require 'blue_jay/clients/twitter_client'
require 'blue_jay/clients/linked_in_client'
require 'blue_jay/clients/facebook_client'

require 'blue_jay/parser'
require 'blue_jay/parsers/twitter_parser'
require 'blue_jay/parsers/linked_in_parser'
require 'blue_jay/parsers/facebook_parser'

# 'alias' TwitterClient as Client
# to preserve pre-3.0 references...
BlueJay::Client = BlueJay::TwitterClient