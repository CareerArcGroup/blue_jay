# frozen_string_literal: true

module BlueJay
  class TwitterEnterpriseClient < OAuthClient
    # ========================================================================
    # Client Initializers and Public Methods
    # ========================================================================

    def initialize(options = {})
      options[:site] ||= 'https://data-api.twitter.com'
      options[:path_prefix] ||= ''

      super(options)
    end

    def totals(options = {})
      params = default_totals_options.merge(options)
      post('/insights/engagement/totals', params.to_json)
    end

    def historical(start_date = 1.day.ago.to_date, end_date = 1.minute.ago.to_date, options = {})
      params = default_totals_options.merge(options)
      params[:start] = start_date.to_s
      params[:end] = end_date.to_s
      post('/insights/engagement/historical', params.to_json)
    end

    def default_totals_options
      {
        engagement_types: %w[impressions engagements favorites retweets],
        groupings: {
          by_tweet_by_type: {
            group_by: %w[tweet.id engagement.type]
          }
        }
      }
    end

    def default_historical_options
      {
        engagement_types: %w[impressions engagements favorites retweets replies video_views url_clicks hashtag_clicks detail_expands permalink_clicks email_tweet user_follows user_profile_clicks],
        groupings: {
          by_tweet_by_day: {
            group_by: %w[tweet.id engagement.type engagement.day]
          }
        }
      }
    end

    protected

    def add_standard_headers(headers = {})
      super(headers.merge(
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      ))
    end

    def response_parser
      BlueJay::TwitterParser
    end
  end
end
