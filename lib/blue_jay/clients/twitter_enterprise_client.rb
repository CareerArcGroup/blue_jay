
module BlueJay
  class TwitterEnterpriseClient < OAuthClient

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://data-api.twitter.com'
      options[:path_prefix] ||= ''

      super(options)
    end

    def historical(start_date = 1.day.ago.to_date, end_date = 1.minute.ago.to_date, options={})
      post('/insights/engagement/historical', options.merge("start": start_date.to_s, "end": end_date.to_s, engagement_types: ["impressions", "engagements", "favorites", "retweets", "replies", "video_views", "url_clicks","hashtag_clicks", "detail_expands", "permalink_clicks", "email_tweet", "user_follows", "user_profile_clicks"], groupings: {by_tweet_by_day: {group_by: ["tweet.id", "engagement.day", "engagement.type"]}}).to_json)
    end

    protected

    def add_standard_headers(headers={})
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
