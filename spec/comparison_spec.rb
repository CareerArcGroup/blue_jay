
require 'spec_helper'
require 'yaml'
require 'twitter_oauth'

include BlueJay
describe BlueJay do

	before do

		# get the Twitter credentials from a file.
		# if the file is missing, alert the user...
		config_file_path = File.expand_path("../spec_config.yml", __FILE__)

		unless File.exists? config_file_path
			raise "Please rename spec/spec_config.yml.sample " +
					      "to spec_config.yml and provide your Twitter API" +
					      "credentials and test settings for use in these tests."
		end

		@config = YAML::load(
				File.read(config_file_path)
		)

		@friend_screen_name = @config["settings"]["friend_screen_name"]
		@friend_id = @config["settings"]["friend_id"]

		# map the credentials to a symbol-keyed hash
		# and pass them in as options to the client...
		credentials_hash = @config["credentials"].inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo }

		@client = TwitterClient.new(credentials_hash)
		@old_client = TwitterOAuth::Client.new(credentials_hash)

	end

	context "when compared with the Twitter OAuth gem" do

		context "with valid Twitter OAuth credentials" do

			# it "matches the 'authorized?' method" do
			# 	new_result = @client.authorized?
			# 	old_result = @old_client.authorized?
			# 	new_result.should eql old_result
			# end

			it "matches the 'info' method" do
				new_result = @client.account_info
				old_result = @old_client.info
				new_result.data.should == old_result
			end

			it "matches the 'rate_limit_status' method" do
				new_result = @client.rate_limit_status
				old_result = @old_client.rate_limit_status
				new_result.data.should == old_result
			end

			it "matches the 'user_timeline' method" do
				new_result = @client.recent_tweets(@friend_id)
				old_result = @old_client.user_timeline(:user_id => @friend_id)
				new_result.data.should == old_result
			end

			it "matches the 'follower_ids' method" do
				new_result = @client.follower_ids(@friend_id)
				old_result = @old_client.followers_ids(:user_id => @friend_id)
				new_result.data.should == old_result
			end

		end

	end

end