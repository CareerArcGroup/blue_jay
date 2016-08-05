
require 'spec_helper'
require 'yaml'
include BlueJay

config = SpecHelper::Config.new(BlueJay::FacebookClient)

describe FacebookClient do

  it "get an OK response from the Facebook test endpoint" do
    config.client.should be_connected
  end

  context "with valid Facebook credentials" do

    it "is authorized" do
      config.client.should be_authorized
      config.client.access_token_expires_at.nil?.should be false
    end

    it "can get user account info" do
      response = config.client.account_info
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it "can share" do
      response = config.client.share(message: "Hello World from dimension #{Random.rand(9999)+1}")
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it "can get a list of the users's albums" do
      response = config.client.albums
      response.successful?.should be true
      response.data["data"].nil?.should be false
    end

    it "can upload a photo to the app album" do
      ocean = File.new(File.expand_path("../assets/profile_banner.jpg", __FILE__))

      response = config.client.upload_photo(ocean, message: "This is a banner", no_story: true)
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end
  end

  context "with invalid Facebook credentials" do
    it "is not authorized" do
      config.unauthorized_client.should_not be_authorized
    end
  end

end
