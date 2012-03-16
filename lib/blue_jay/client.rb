
module BlueJay
	class Client

		def initialize(options={})
			@consumer_key = options[:consumer_key]
		  @consumer_secret = options[:consumer_secret]
		  @token = options[:token]
		  @secret = options[:secret]
		  @proxy = options[:proxy]
	  end

		def authorize(token, secret, options={})
			request_token = OAuth::RequestToken.new(consumer, token, secret)
			@access_token = request_token.get_access_token(options)
			@token = @access_token.token
			@secret = @access_token.secret
			@access_token
		end

		def is_connected?
			get_raw("/help/test.json") == %q("ok")
		end

		private

		def consumer
			@consumer ||= OAuth::Consumer.new(
				@consumer_key,
				@consumer_secret,
				{ :site => 'http://api.twitter.com', :request_endpoint => @proxy }
			)
		end

		def access_token
			@access_token ||= OAuth::AccessToken.new(consumer, @token, @secret)
		end

		def get(path, headers={})
			JSON.parse(get_raw(path, headers))
		end

		def get_raw(path, headers={})
			add_standard_headers(headers)
			access_token.get("/1#{path}", headers).body
		end

		def post(path, body='', headers={})
			JSON.parse(post_raw(path,body,headers))
		end

		def post_raw(path, body='', headers={})
			add_standard_headers(headers)
			access_token.post("/1#{path}", body, headers).body
		end

		def add_standard_headers(headers={})
			headers.merge!("User-Agent" => "blue_jay gem v#{BlueJay::VERSION}")
		end

	end
end