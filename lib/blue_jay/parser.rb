module BlueJay
	class Parser
		def self.parse_response(response, data)
			response.successful = false
			response.data = nil
			response.errors = nil
		end
	end
end