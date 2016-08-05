
require 'spec_helper'
require 'yaml'
include BlueJay

config = SpecHelper::Config.new(BlueJay::LinkedInClient)

describe LinkedInClient do

  it "get an OK response from the LinkedIn test endpoint" do
    config.client.should be_connected
  end

  context "with valid LinkedIn credentials" do

    it "is authorized" do
      config.client.should be_authorized
    end

    it "can get user account info" do
      response = config.client.account_info
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it "can share" do
      response = config.client.share(
        comment: "Hello World from dimension #{Random.rand(9999)+1}",
        visibility: { code: 'anyone' },
        content: {
          title: "This is the title",
          description: "This is the description",
          'submitted-url' => "http://www.google.com"
        })

      response.successful?.should be true
      response.data["updateKey"].nil?.should be false
    end
  end

  context "with invalid LinkedIn credentials" do
    it "is not authorized" do
      config.unauthorized_client.should_not be_authorized
    end
  end

end
