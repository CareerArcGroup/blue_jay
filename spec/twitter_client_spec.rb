
require 'spec_helper'
require 'yaml'
include BlueJay

describe TwitterClient do

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

    @friend_screen_name = @config["twitter"]["settings"]["friend_screen_name"]
    @friend_id = @config["twitter"]["settings"]["friend_id"]

    # map the credentials to a symbol-keyed hash
    # and pass them in as options to the client...
    credentials_hash = @config["twitter"]["credentials"].inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo }

    @client = TwitterClient.new(credentials_hash)

    # and create some clients that will misbehave...
    # like this one, which will not be able to connect to Twitter (unless you proxy it)
    @disconnected_client = TwitterClient.new(credentials_hash.merge(:proxy => 'localhost'))
    @unauthorized_client = TwitterClient.new

  end

  it "get an OK response from the Twitter test endpoint" do
    @client.should be_connected
  end

  it "returns responses that can be used as a hash" do
    response = @client.rate_limit_status
    response["resources"].should_not be_nil
  end

  context "with valid Twitter OAuth credentials" do

    it "is authorized" do
      @client.should be_authorized
    end

    it "can get user account info" do
      response = @client.account_info
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it "can check the account rate limit" do
      response = @client.rate_limit_status
      response.successful?.should be true
      response["resources"].should_not be_nil
    end

    it "can tweet" do
      response = @client.tweet("Hello World from dimension #{Random.rand(9999)+1}")
      response.successful?.should be true
      response.data["id"].nil?.should be false

      # this one fails with "Could not authenticate you" in
      # the case when we're not encoding/calculating the OAuth
      # signature correctly (added after failed change from 3.5 to 4.0.2)
      response = @client.tweet("Can you recommend anyone for this #job? Barista (US) - http://bit.ly/1LQN6fZ #Hospitality *1050 SW ALDER, #{Random.rand(9999)+1}, OR #Veterans #Hiring")
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it "can tweet with media" do
      banner = File.new(File.expand_path("../assets/profile_banner.jpg", __FILE__))
      response = @client.tweet_with_media("Hello world from dimension #{rand(9999) + 1}", banner)
      response.should be_successful
    end

    it "can tweet with media from remote url" do
      require 'open-uri'
      url = "http://dev.tweetmyjobs.com.s3.amazonaws.com/social_media_profiles/218/twitter_images/7395635.jpg"
      media = open(url)
      response = @client.tweet_with_media("Media with remote url #{rand(9999) + 1}", media)
      response.should be_successful
    end

    it "can un-tweet" do
      account_info = @client.account_info.data
      last_tweet_id = account_info["status"]["id"]
      last_tweet_id.should be > 0

      response = @client.un_tweet(last_tweet_id)
      response.successful?.should be true
      response.data["id"].should be last_tweet_id
    end

    it "can friend someone by user id" do
      response = @client.add_friend(@friend_id)
      response.should be_successful
      response.data["id"].should == @friend_id
    end

    it "can un-friend someone by user_id" do
      response = @client.un_friend(@friend_id)
      response.should be_successful
      response.data["id"].should == @friend_id
    end

    it "can friend someone by screen name" do
      response = @client.add_friend_by_screen_name(@friend_screen_name)
      response.should be_successful
      response.data["screen_name"].should == @friend_screen_name
    end

    it "can un-friend someone by screen name" do
      response = @client.un_friend_by_screen_name(@friend_screen_name)
      response.should be_successful
      response.data["screen_name"].should == @friend_screen_name
    end

    it "can update the account profile" do
      account_info = @client.account_info.data

      original_name = account_info["name"]
      original_location = account_info["location"]
      original_url = account_info["url"]
      original_description = account_info["description"]
      random = Random.rand(9999)

      response = @client.update_profile(
        :name => "Roosifer",
        :location => "Hades, Netherworld",
        :url => "http://www.internships.com",
        :description => "#{original_description} #{random}"
      )

      response.should be_successful
      response.data["name"].should == "Roosifer"
      response.data["location"].should == "Hades, Netherworld"

      # TODO: for some reason the api is not updating the url
      #response.data["url"].should == "http://www.internships.com"
      response.data["description"].should == "#{original_description} #{random}"

      # reset the information to how it was before...
      reset_response = @client.update_profile(
          :name => original_name,
          :location => original_location,
          :url => original_url,
          :description => original_description
      )

      reset_response.should be_successful
    end

    it "can retrieve a user's recent tweets" do
      response = @client.recent_tweets(user_id: @friend_id)
      response.should be_successful
      response.data.should be_a_kind_of Array
      response.data.size.should be > 0
    end

    it "can retrieve a user's follower's IDs" do
      response = @client.follower_ids(@friend_id)
      response.should be_successful
      response.data["ids"].should be_a_kind_of Array
      response.data["ids"].size.should be > 0
    end

  end

  context "with invalid Twitter OAuth credentials" do
    it "is not authorized" do
      @unauthorized_client.should_not be_authorized
    end
  end

  describe "#update_profile_banner" do
    let(:banner) { File.new(File.expand_path("../assets/profile_banner.jpg", __FILE__)) }

    context "with valid image" do
      it "updates the profile banner image" do
        response = @client.update_profile_banner(banner)
        response.status.should be Net::HTTPCreated
        response.should be_successful
      end
    end
  end

  describe "#update_profile_background_image" do
    let(:background_image) { File.new(File.expand_path("../assets/Twitter-BG_2_bg-image.jpg", __FILE__)) }

    context "with valid image" do
      it "updates the profile background image" do
        response = @client.update_profile_background_image(background_image)
        response.status.should be Net::HTTPOK
        response.should be_successful
      end
    end
  end

  describe "#update_profile_image" do
    let(:image) { File.new(File.expand_path("../assets/Twitter-BG_2_bg-image.jpg", __FILE__)) }

    context "with valid image" do
      it "updates the profile image" do
        response = @client.update_profile_image(image)
        response.status.should be Net::HTTPOK
        response.should be_successful
      end
    end
  end

  describe "#update_profile_colors" do
    let(:bg_color) { "FF00FF" }
    context "with valid hex color" do
      it "updates the profile background color" do
        response = @client.update_profile({:profile_background_color => bg_color})
        response.status.should be Net::HTTPOK
        response.should be_successful
      end
    end
  end

end
