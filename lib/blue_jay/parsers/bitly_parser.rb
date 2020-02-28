# frozen_string_literal: true

module BlueJay
  class BitlyParser < Parser
    def self.parse_response(response, data)
      super(response, data)

      response.status     = data.class
      response.successful = data.is_a?(Net::HTTPSuccess)

      begin
        response.data = (response.raw_data? || data.body.length < 2 ? data.body : JSON.parse(data.body))
      rescue JSON::ParserError => e
        response.data = data.body
        response.successful = false
        response.errors = e
      end
    end
  end
end
