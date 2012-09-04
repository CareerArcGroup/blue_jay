
require 'blue_jay/exceptions/rate_limit_exception'

module BlueJay
	class Response

		RATE_LIMIT_HEADER ="X-RateLimit-Limit"
		RATE_LIMIT_REMAINING_HEADER = "X-RateLimit-Remaining"
		RATE_LIMIT_RESET_HEADER = "X-RateLimit-Reset"

		def initialize(response, options={})
			@raw_data = options[:raw_data]
			@debug = options[:debug]
			parse_response(response)
		end

		def successful?; @success	end
		def data;	@data	end
		def errors; @errors end
		def status; @status	end
		def rate_limited?; @rate_limit_remaining == 0 end
		def rate_limit; @rate_limit end
		def rate_limit_remaining; @rate_limit_remaining end
		def rate_limit_reset_time; @rate_limit_reset_time end

		def method_missing(method, *args, &block)
			@data.send(method, *args)
		end

		private

		def parse_response(response)
			@success = false
			@data = nil
			@errors = nil

			puts "BlueJay => #{response.inspect}" if @debug

			# handle the case of the empty or missing response...
			return if response.nil? || !response.kind_of?(Net::HTTPResponse)

			@status = response.class

			get_rate_limit_info(response)
			raise RateLimitException if rate_limited?

			begin

				# try to parse the response as JSON (unless @raw_data)...
				@data = (@raw_data) ? response.body : JSON.parse(response.body)
				@errors = @data["errors"] if @data.is_a?(Hash)

				# errors can be detected by the status code (not Success) or
				# by the presence of an "errors" object in the de-serialized response...
				@success = (response.kind_of?(Net::HTTPSuccess) && @errors.nil?)

			rescue JSON::ParserError => e
				# if we can't parse the response, return
				# a json response anyway that gives us information
				# about the response in a well structured manner...
				@data = response.body
				@success = false
				@errors = e
			end
		end

		def get_rate_limit_info(response)
			reset_time_ticks = response[RATE_LIMIT_RESET_HEADER]

			@rate_limit = response[RATE_LIMIT_HEADER]
			@rate_limit_remaining = response[RATE_LIMIT_REMAINING_HEADER]
			@rate_limit_reset_time = (reset_time_ticks) ? Time.at(reset_time_ticks.to_i) : nil
		end

	end
end