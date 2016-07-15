
require 'spec_helper'
require 'yaml'
include BlueJay

describe FacebookClient do

  before do

    # get the Twitter credentials from a file.
    # if the file is missing, alert the user...
    config_file_path = File.expand_path("../spec_config.yml", __FILE__)

    unless File.exists? config_file_path
      raise "Please rename spec/spec_config.yml.sample " +
        "to spec_config.yml and provide your Facebook API" +
        "credentials and test settings for use in these tests."
    end

    @config = YAML::load(
      File.read(config_file_path)
    )

    @friend_id = @config["facebook"]["settings"]["friend_id"]

    # map the credentials to a symbol-keyed hash
    # and pass them in as options to the client...
    credentials_hash = @config["facebook"]["credentials"].inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo }

    @client = FacebookClient.new(credentials_hash)

    # and create some clients that will misbehave...
    # like this one, which will not be able to connect to Twitter (unless you proxy it)
    @disconnected_client = FacebookClient.new(credentials_hash.merge(:proxy => 'localhost'))
    @unauthorized_client = FacebookClient.new

  end

  it "get an OK response from the Facebook test endpoint" do
    @client.should be_connected
  end

  context "with valid Facebook credentials" do

    it "is authorized" do
      @client.should be_authorized
    end

    it "can get user account info" do
      response = @client.account_info
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it "can share" do
      response = @client.share(message: "Hello World from dimension #{Random.rand(9999)+1}")
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it "can get a list of the users's albums" do
      response = @client.albums
      response.successful?.should be true
      response.data["data"].nil?.should be false
    end

    it "can upload a photo to the app album" do
      ocean = File.new(File.expand_path("../assets/profile_banner.jpg", __FILE__))

      response = @client.upload_photo(ocean, message: "This is a banner", no_story: true)
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it "can upload a photo to the timeline and share a post about it" do
      ocean = File.new(File.expand_path("../assets/fishing_cat.jpg", __FILE__))

      albums = @client.albums
      timeline_album = albums.data["data"].find { |a| a["name"] == "Timeline Photos" }
      album_id = timeline_album["id"]

      response = @client.upload_photo(ocean, album_id: album_id, message: "This is a fishing cat", no_story: true)
      response.successful?.should be true
      response.data["id"].nil?.should be false

      photo_id = response.data["id"]

      response = @client.share(message: "Hello World (with fishing cat) from dimension #{Random.rand(9999)+1}", object_attachment: photo_id)
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

  end

  context "with invalid Facebook credentials" do
    it "is not authorized" do
      @unauthorized_client.should_not be_authorized
    end
  end

end
