require 'spec_helper'
require 'yaml'
include BlueJay

config = SpecHelper::Config.new(BlueJay::InstagramClient)

describe InstagramClient do

  it "get an OK response from the LinkedIn test endpoint" do
    config.client.should be_connected
  end

  context "with valid Instagram credentials" do

    it "is authorized" do
      config.client.should be_authorized
    end

    it "can get user account info" do
      response = config.client.account_info
      response.successful?.should be true
      response.data["data"]["id"].nil?.should be false
    end

    it "can get user's recent media" do
      response = config.client.recent_media(count: 1)
      response.successful?.should be true
      response.data["data"].count.should be 1
    end
  end

  context "with invalid Instagram credentials" do
    it "is not authorized" do
      config.unauthorized_client.should_not be_authorized
    end
  end

end
