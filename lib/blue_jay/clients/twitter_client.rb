
module BlueJay
  class TwitterClient < OAuthClient

    filtered_attributes :snipped_data

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://api.twitter.com'
      options[:authorize_path] ||= '/oauth/authenticate'
      options[:path_prefix] ||= '/1.1'

      super(options)
    end

    # NOTE: the rate_limit_status endpoint allows 180
    # calls in a 15 minutes window. This is much higher
    # than calling verify_credentials which only allows
    # 15 calls.
    def connected?
      authorized?
    end

    def authorized?
      data = rate_limit_status
      data && data["resources"] && data["resources"].count > 0
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    # Returns an HTTP 200 OK response code and a representation of the requesting
    # user if authentication was successful; returns a 401 status code and an error
    # message if not. Use this method to test if supplied user credentials are valid.
    def account_info
      get('/account/verify_credentials.json')
    end

    # Returns the remaining number of API requests available to the requesting user
    # before the API limit is reached for the current hour. Calls to rate_limit_status
    # do not count against the rate limit. If authentication credentials are provided,
    # the rate limit status for the authenticating user is returned. Otherwise, the rate
    # limit status for the requesting IP address is returned.
    def rate_limit_status
      get('/application/rate_limit_status.json')
    end

    # Sets values that users are able to set under the "Account" tab of their settings
    # page. Only the parameters specified will be updated.
    # Options: name, url, location, description
    def update_profile(options={})
      post('/account/update_profile.json', options)
    end

    # Updates the authenticating user's profile image. Note that this method
    # expects raw multipart data, not a URL to an image.
    def update_profile_image(image)
      encoded = Base64.encode64(File.read(image))

      post('/account/update_profile_image.json', image: encoded)
    end

    # Updates the authenticating user's profile background image. Note that
    # this method expects raw multipart data, not a URL to an image.
    def update_profile_background_image(image)
      encoded = Base64.encode64(File.read(image))

      post('/account/update_profile_background_image.json', image: encoded)
    end

    # Updates the authenticating user's profile header image. Not that
    # this method expects raw multipart data, not a URL to an image.
    def update_profile_banner(image)
      encoded = Base64.encode64(File.read(image))

      post('/account/update_profile_banner.json', banner: encoded)
    end

    alias_method :info, :account_info
    alias_method :update_profile_colors, :update_profile

    # ============================================================================
    # User Methods - These act on specified users
    # ============================================================================

    # Allows the authenticating users to follow the user specified in the ID parameter.
    # Returns the befriended user in the requested format when successful. Returns a string
    # describing the failure condition when unsuccessful. If you are already friends with the
    # user a HTTP 403 may be returned, though for performance reasons you may get a 200 OK
    # message even if the friendship already exists.
    def add_friend(friend_id, follow=true)
      post("/friendships/create.json", user_id: friend_id, follow: follow)
    end

    # Allows the authenticating users to follow the user specified in the ID parameter.
    # Returns the befriended user in the requested format when successful. Returns a string
    # describing the failure condition when unsuccessful. If you are already friends with the
    # user a HTTP 403 may be returned, though for performance reasons you may get a 200 OK
    # message even if the friendship already exists.
    def add_friend_by_screen_name(screen_name, follow=true)
      post("/friendships/create.json", screen_name: screen_name, follow: follow)
    end

    # Allows the authenticating users to un-follow the user specified in the ID parameter.
    # Returns the un-followed user in the requested format when successful. Returns a string
    # describing the failure condition when unsuccessful.
    def un_friend(friend_id)
      post("/friendships/destroy.json", user_id: friend_id)
    end

    # Allows the authenticating users to un-follow the user specified in the ID parameter.
    # Returns the un-followed user in the requested format when successful. Returns a string
    # describing the failure condition when unsuccessful.
    def un_friend_by_screen_name(screen_name)
      post("/friendships/destroy.json", screen_name: screen_name)
    end

    # Test for the existence of friendship between two users. Will return true if user_a follows user_b,
    # otherwise will return false. Authentication is required if either user A or user B are protected.
    # Additionally the authenticating user must be a follower of the protected user.
    # Options: cursor
    def follower_ids(user_id, options={})
      get("/followers/ids.json", options.merge(user_id: user_id))
    end

    # Test for the existence of friendship between two users. Will return true if user_a follows user_b,
    # otherwise will return false. Authentication is required if either user A or user B are protected.
    # Additionally the authenticating user must be a follower of the protected user.
    # Options: cursor
    def follower_ids_by_screen_name(screen_name, options={})
      get("/followers/ids.json", options.merge(screen_name: screen_name))
    end

    # Returns detailed information about the relationship between two users.
    def get_friendship(a, b)
      get("/friendships/show.json", source_screen_name: a, target_screen_name: b)
    end

    alias :friend :add_friend_by_screen_name
    alias :unfriend :un_friend_by_screen_name

    # ============================================================================
    # Status Methods - These act on Tweets
    # ============================================================================

    # Updates the authenticating user's status, also known as tweeting. For each update attempt,
    # the update text is compared with the authenticating user's recent tweets. Any attempt that
    # would result in duplication will be blocked, resulting in a 403 error. Therefore, a user
    # cannot submit the same status twice in a row. While not rate limited by the API a user is
    # limited in the number of tweets they can create at a time. If the number of updates posted by
    # the user reaches the current allowed limit this method will return an HTTP 403 error.
    # Options:
    #   in_reply_to_status_id   The ID of an existing status that the update is in reply to.
    #   lat                     The latitude of the location this tweet refers to.
    #   long                    The longitude of the location this tweet refers to.
    #   place_id                A place in the world (ID).
    #   display_coordinates     Whether or not to put a pin on the exact coordinates of the tweet.
    #
    def tweet(message, options={})
      post("/statuses/update.json", options.merge(status: message))
    end

    # Tweets with a picture :-)
    def tweet_with_media(message, image, options = {})
      post("/statuses/update_with_media.json", options.merge(:status => message, :'media[]' => image))
    end

    # Destroys the status specified by the required ID parameter. The authenticating user must
    # be the author of the specified status. Returns the destroyed status if successful.
    def un_tweet(tweet_id)
      post("/statuses/destroy/#{tweet_id}.json")
    end

    # Returns the 20 most recent statuses posted by the authenticating user. It is also possible
    # to request another user's timeline by using the screen_name or user_id parameter. The other
    # users timeline will only be visible if they are not protected, or if the authenticating user's
    # follow request was accepted by the protected user.
    def recent_tweets(options={})
      get("/statuses/user_timeline.json", options)
    end

    alias :update :tweet
    alias :update_with_media :tweet_with_media
    alias :status_destroy :un_tweet
    alias :user_timeline :recent_tweets

    protected

    def response_parser
      BlueJay::TwitterParser
    end

    # filter raw data out of logs, we don't need to
    # see binary image data...
    def snipped_data
      /(?:image|banner)=(?<snipped>[^&"]+)/
    end
  end
end
