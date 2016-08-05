module BlueJay
  class Request
    attr_reader :method, :uri, :body, :headers

    def initialize(method, uri, body=nil, headers={})
      @method = method
      @uri = uri
      @body = body
      @headers = headers
    end

    def to_s
      "#{method.to_s.upcase} #{friendly_uri}"
    end

    private

    def friendly_uri
      uri.to_s.gsub("?#{uri.query}", "")
    end
  end
end