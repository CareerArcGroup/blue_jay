
module BlueJay
  class FacebookClient < Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://graph.facebook.com'
      options[:authorize_path] ||= '/oauth/authorize'
      options[:request_token_path] ||= '/oauth/request_token'
      options[:access_token_path] ||= '/oauth/access_token'
      
      super(options)
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    protected

    def response_parser
      BlueJay::FacebookParser
    end

  end
end
