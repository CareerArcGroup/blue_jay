# frozen_string_literal: true

module BlueJay
  class TwitterEnterpriseClient < OAuthClient

    # ========================================================================
    # Client Initializers and Public Methods
    # ========================================================================

    def initialize(options = {})
      options[:site] ||= 'https://ads-api.twitter.com'
      options[:path_prefix] ||= '/6' # version

      super(options)
    end

    # ========================================================================
    # Accounts
    # ========================================================================

    def accounts
      get('/accounts')
    end

    # ========================================================================
    # Campaigns
    # ========================================================================    

    def campaigns(account_id, options = {})
      get("/accounts/#{account_id}/campaigns", options)
    end

    # ========================================================================
    # Funding Instruments
    # ========================================================================    

    def funding_instruments(account_id, options = {})
      get("/accounts/#{account_id}/funding_instruments", options)
    end

    protected

    def response_parser
      BlueJay::TwitterParser
    end
  end
end
