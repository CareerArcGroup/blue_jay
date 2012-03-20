module BlueJay
	class Response

		def initialize(response)
			 parse_response(response)
		end

		def successful?; @success	end
		def data;	@data	end
		def status; @status	end

		private

		def parse_response(response)
			@success = false

			# handle the case of the empty or missing response...
			return if response.nil? || !response.kind_of?(Net::HTTPResponse)
			@status = response.class

			begin
				# try to parse the response as JSON...
				@data = JSON.parse(response.body)
				@success = (response.kind_of?(Net::HTTPSuccess))
			rescue JSON::ParserError => e
				# if we can't parse the response, return
				# a json response anyway that gives us information
				# about the response in a well structured manner...
				@data = response.body
				@parse_error = e
			end
		end

	end
end