# frozen_string_literal: true

module BlueJay
  class TwitterAdsClient < OAuthClient

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

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/accounts#get-accounts
    def accounts
      get('/accounts')
    end

    # ========================================================================
    # Campaigns
    # ========================================================================    

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/campaigns#get-accounts-account-id-campaigns-campaign-id
    def campaigns(account_id, options = {})
      get("/accounts/#{account_id}/campaigns", options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/campaigns#post-accounts-account-id-campaigns
    def create_campaign(account_id, options = {})
      post("/accounts/#{account_id}/campaigns", options)
    end

    # ========================================================================
    # Funding Instruments
    # ========================================================================

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/funding-instruments#get-accounts-account-id-funding-instruments
    def funding_instruments(account_id, options = {})
      get("/accounts/#{account_id}/funding_instruments", options)
    end

    # ========================================================================
    # Line Items
    # ========================================================================

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/line-items#get-accounts-account-id-line-items
    def line_items(account_id, options = {})
      get("/accounts/#{account_id}/line_items", options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/line-items#post-accounts-account-id-line-items
    def create_line_item(account_id, options = {})
      post("/accounts/#{account_id}/line_items", options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/line-items#put-accounts-account-id-line-items-line-item-id
    def update_line_item(account_id, line_item_id, options = {})
      put("/accounts/#{account_id}/line_items/#{line_item_id}", options)
    end

    # ========================================================================
    # Targeting Criteria
    # ========================================================================

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-criteria#get-accounts-account-id-targeting-criteria
    def targeting_criteria(account_id, line_item_ids, options = {})
      get("/accounts/#{account_id}/targeting_criteria", options.merge(line_item_ids: line_item_ids))
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-criteria#post-accounts-account-id-targeting-criteria
    def add_targeting_criterion(account_id, line_item_id, targeting_type, operator_type, targeting_value, options = {})
      post("/accounts/#{account_id}/targeting_criteria", options.merge(
        line_item_id:    line_item_id,
        operator_type:   operator_type,
        targeting_type:  targeting_type,
        targeting_value: targeting_value
      ))
    end

    # ========================================================================
    # Targeting Options
    # ========================================================================

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-app-store-categories
    def targeting_app_store_categories(options = {})
      get('/targeting_criteria/app_store_categories', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-behavior-taxonomies
    def targeting_behavior_taxonomies(options = {})
      get('/targeting_criteria/behavior_taxonomies', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-behaviors
    def targeting_behaviors(options = {})
      get('/targeting_criteria/behaviors', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-conversations
    def targeting_conversations(options = {})
      get('/targeting_criteria/conversations', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-devices
    def targeting_devices(options = {})
      get('/targeting_criteria/devices', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-events
    def targeting_events(options = {})
      get('/targeting_criteria/events', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-interests
    def targeting_interests(options = {})
      get('/targeting_criteria/interests', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-languages
    def targeting_languages(options = {})
      get('/targeting_criteria/languages', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-locations
    def targeting_locations(options = {})
      get('/targeting_criteria/locations', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-network-operators
    def targeting_network_operators(options = {})
      get('/targeting_criteria/network_operators', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-platform-versions
    def targeting_platform_versions(options = {})
      get('/targeting_criteria/targeting_platform_versions', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-platforms
    def targeting_platforms(options = {})
      get('/targeting_criteria/platforms', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-tv-markets
    def targeting_tv_markets(options = {})
      get('/targeting_criteria/tv_markets', options)
    end

    # https://developer.twitter.com/en/docs/ads/campaign-management/api-reference/targeting-options#get-targeting-criteria-tv-shows
    def targeting_tv_shows(options = {})
      get('/targeting_criteria/tv_shows', options)
    end

    protected

    def response_parser
      BlueJay::TwitterParser
    end
  end
end
