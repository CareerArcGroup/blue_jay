
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
    end

    it "can get user account info" do
      response = config.client.account_info
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    # DEPRECATED
    # see https://developers.facebook.com/docs/graph-api/changelog/breaking-changes#login-4-24
    # it "can share" do
    #   response = config.client.share(message: "Hello World from dimension #{Random.rand(9999)+1}")
    #   response.successful?.should be true
    #   response.data["id"].nil?.should be false
    # end

    it "can get a list of the users's albums" do
      response = config.client.albums
      response.successful?.should be true
      response.data["data"].nil?.should be false
    end

    # DEPRECATED
    # see https://developers.facebook.com/docs/graph-api/changelog/breaking-changes#login-4-24
    # it "can upload a photo to the app album" do
    #   ocean = File.new(File.expand_path("../assets/profile_banner.jpg", __FILE__))

    #   response = config.client.upload_photo(ocean, message: "This is a banner", no_story: true, album_id: "1122787084448806")
    #   response.successful?.should be true
    #   response.data["id"].nil?.should be false
    # end

    it "can retrieve a page access token" do
      response = config.client.page_access_token(config.settings["page_id"])

      response.successful?.should be true
      response.data["access_token"].nil?.should be false
    end

    it "can create a page tab" do
      token_response = config.client.page_access_token(config.settings["page_id"])
      access_token = token_response.data["access_token"]
      response = config.client.create_tab(config.settings["page_id"], app_id: config.consumer_key, access_token: access_token)

      response.successful?.should be true
    end

  end

  context "with invalid Facebook credentials" do
    it "is not authorized" do
      config.unauthorized_client.should_not be_authorized
    end
  end

  context "with invalid App Secret Proof" do
    it "is not authorized" do
      response = config.client.account_info(appsecret_proof: "DUMMYPROOF")
      response.successful?.should be false
    end
  end

end
