
module BlueJay
  class FacebookClient < Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://graph.facebook.com'
      options[:http_method] ||= :get
      
      super(options)
    end

    def request_token
      raise NotImplementedError, 'FacebookClient does not support this method'
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    def account_info()
      get('/me')
    end

    protected

    def response_parser
      BlueJay::FacebookParser
    end

  end
end
