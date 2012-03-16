
require 'spec_helper'
require 'yaml'
include BlueJay

describe Client do

	before do

		# get the Twitter credentials from a file.
		# if the file is missing, alert the user...
		credential_file_path = File.expand_path("../credentials.yml", __FILE__)

		unless File.exists? credential_file_path
			raise "Please rename spec/credentials.yml.sample " +
				"to credentials.yml and provide your Twitter API" +
				"credentials there for use in these tests."
		end

		credentials = YAML::load(
			File.read(credential_file_path)
		)

		# map the credentials to a symbol-keyed hash
		# and pass them in as options to the client...
		@client = Client.new(credentials.inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo })

	end

	it "get an OK response from the Twitter spec endpoint" do
		@client.is_connected?.should eq(true)
	end

end