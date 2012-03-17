
require 'blue_jay/account'
require 'blue_jay/status'
require 'blue_jay/response'
require 'blue_jay/user'

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

		def connected?
			get_raw("/help/test.json").body == %q("ok")
		end

		def authorized?
			response = get_raw("/account/verify_credentials.json")
			response.class == Net::HTTPOK
		end

		def request_token(options={})
			consumer.get_request_token(options)
		end

		def authentication_request_token(options={})
			consumer.options[:authorize_path] = '/oauth/authenticate'
			request_token(options)
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
			BlueJay::Response.new(get_raw(path, headers))
		end

		def get_raw(path, headers={})
			add_standard_headers(headers)
			access_token.get("/1#{path}", headers)
		end

		def post(path, body='', headers={})
			BlueJay::Response.new(post_raw(path,body,headers))
		end

		def post_raw(path, body='', headers={})
			add_standard_headers(headers)
			access_token.post("/1#{path}", body, headers)
		end

		def add_standard_headers(headers={})
			headers.merge!("User-Agent" => "blue_jay gem v#{BlueJay::VERSION}")
		end

	end
end