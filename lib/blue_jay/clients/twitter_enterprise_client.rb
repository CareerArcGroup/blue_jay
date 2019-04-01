
module BlueJay
  class TwitterEnterpriseClient < OAuth2Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://data-api.twitter.com'
      options[:authorize_url] ||= 'https://api.twitter.com/oauth/authorize'
      options[:token_url]     ||= 'https://api.twitter.com/oauth/access_token'
      options[:path_prefix] ||= ''

      super(options)
    end

    def historical(start_date = 1.day.ago.to_date, end_date = 1.minute.ago.to_date, options={})
      post('/insights/engagement/historical', options.merge(start: start_date.to_s, end: end_date.to_s))
    end

    protected

    def response_parser
      BlueJay::TwitterParser
    end
  end
end
