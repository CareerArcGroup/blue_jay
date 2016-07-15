
require 'spec_helper'
require 'yaml'
include BlueJay

describe LinkedInClient do

  before do

    # get the LinkedIn credentials from a file.
    # if the file is missing, alert the user...
    config_file_path = File.expand_path("../spec_config.yml", __FILE__)

    unless File.exists? config_file_path
      raise "Please rename spec/spec_config.yml.sample " +
        "to spec_config.yml and provide your LinkedIn API" +
        "credentials and test settings for use in these tests."
    end

    @config = YAML::load(
      File.read(config_file_path)
    )

    # map the credentials to a symbol-keyed hash
    # and pass them in as options to the client...
    credentials_hash = @config["linked_in"]["credentials"].inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo }

    @client = LinkedInClient.new(credentials_hash)

    # and create some clients that will misbehave...
    # like this one, which will not be able to connect to LinkedIn (unless you proxy it)
    @disconnected_client = LinkedInClient.new(credentials_hash.merge(:proxy => 'localhost'))
    @unauthorized_client = LinkedInClient.new

  end

  it "get an OK response from the LinkedIn test endpoint" do
    @client.should be_connected
  end

  context "with valid LinkedIn credentials" do

    it "is authorized" do
      @client.should be_authorized
    end

    it "can get user account info" do
      response = @client.account_info
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it "can share" do
      response = @client.share(
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
      @unauthorized_client.should_not be_authorized
    end
  end

end
