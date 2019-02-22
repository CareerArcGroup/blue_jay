require 'spec_helper'
require 'yaml'
include BlueJay

LINKEDIN_TEST_COMPANY_ID = 2414183
LINKEDIN_TEST_COMPANY_URN = "urn:li:organization:2414183"


config = SpecHelper::Config.new(BlueJay::LinkedInClientV2)

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
        {
          content: {
            contentEntities: [
              {
                entityLocation: "http://www.google.com"
              }
            ],
            title: "Test Share with Content"
          },
          distribution: {
            "linkedInDistributionTarget": {}
          },
          owner: LINKEDIN_TEST_COMPANY_URN,
          subject: "Test Share Subject",
          text: {
            text: "Hello World from dimension #{Random.rand(9999)+1}"
          }
        }

      response.successful?.should be true
      response.data["activity"].nil?.should be false
    end


    it "can get company info" do
      response = config.client.company_info(LINKEDIN_TEST_COMPANY_ID)
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end
  end

  context "with invalid LinkedIn credentials" do
    it "is not authorized" do
      config.unauthorized_client.should_not be_authorized
    end
  end

end
