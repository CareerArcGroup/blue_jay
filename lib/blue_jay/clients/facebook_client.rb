
module BlueJay
  class FacebookClient < Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://graph.facebook.com'      
      super(options)
    end

    def authorize_url(redirect_uri)
      "https://www.facebook.com/dialog/oauth?client_id=#{client_id}&redirect_uri=#{CGI.escape(redirect_uri)}"
    end

    def authorize(code, redirect_uri)
      begin
        response = get_raw("/oauth/access_token?client_id=#{client_id}&redirect_uri=#{CGI.escape(redirect_uri)}&client_secret=#{client_secret}&code=#{code}")
        response
        success = response.is_a? Net::HTTPSuccess
        if success
          @access_token, expires_in = response.body.split('&').map {|p| p.split('=').last}
          @access_token_expires_at = Time.now + expires_in.to_i
        end
        success
      rescue Exception => ex
        puts "Exception: #{ex}\n#{ex.backtrace.join("\n")}"; false
      end
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    # ============================================================================
    # Accessors and Options
    # ============================================================================

    def client_id
      options[:client_id]
    end

    def client_secret
      options[:client_secret]
    end

    def access_token
      @access_token
    end

    def access_token_expires_at
      @access_token_expires_at
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    def account_info()
      token_get('/me')
    end

    protected

    def token_get(path)
      get("#{path}#{path.include?('?') ? '&' : '?'}access_token=#{access_token}")
    end

    def response_parser
      BlueJay::FacebookParser
    end

  end
end
