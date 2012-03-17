
module BlueJay
	class Client

		def account_info
			get('/account/verify_credentials.json')
		end

		def rate_limit_status
			get('/account/rate_limit_status.json')
		end

		def update_profile(options={})
			post('/account/update_profile.json', options)
		end

	end
end