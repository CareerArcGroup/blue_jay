module BlueJay
	class Response

		RATE_LIMIT_HEADER ="X-RateLimit-Limit"
		RATE_LIMIT_REMAINING_HEADER = "X-RateLimit-Remaining"
		RATE_LIMIT_RESET_HEADER = "X-RateLimit-Reset"

		def initialize(response, debug = false)
			 parse_response(response, debug)
		end

		def successful?; @success	end
		def data;	@data	end
		def error; @error end
		def status; @status	end
		def rate_limited?; @rate_limit_remaining == 0 end
		def rate_limit; @rate_limit end
		def rate_limit_remaining; @rate_limit_remaining end
		def rate_limit_reset_time; @rate_limit_reset_time end

		private

		def parse_response(response, debug)
			@success = false
			@data = nil
			@error = nil

			puts "BlueJay => #{response.inspect}" if debug

			# handle the case of the empty or missing response...
			return if response.nil? || !response.kind_of?(Net::HTTPResponse)

			@status = response.class
			@rate_limit = response[RATE_LIMIT_HEADER]
			@rate_limit_remaining = response[RATE_LIMIT_REMAINING_HEADER]

			reset_time_ticks = response[RATE_LIMIT_RESET_HEADER]
			@rate_limit_reset_time = (reset_time_ticks) ? Time.at(reset_time_ticks.to_i) : nil

			begin

				# try to parse the response as JSON...
				@data = JSON.parse(response.body)

				# errors can be detected by the status code (not Success) or
				# by the presence of an "error" object in the de-serialized response...
				@success = (response.kind_of?(Net::HTTPSuccess) && !@data.respond_to?(:error))
				@error = @data.error if @data.respond_to?(:error)

			rescue JSON::ParserError => e
				# if we can't parse the response, return
				# a json response anyway that gives us information
				# about the response in a well structured manner...
				@data = response.body
				@error = e
			end
		end

	end
end