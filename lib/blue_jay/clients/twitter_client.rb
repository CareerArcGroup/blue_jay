
module BlueJay
  class TwitterClient < OAuthClient

    filtered_attributes :snipped_data

    MAX_CHUNK_SIZE = 3*1024*1024
    MEDIA_CATEGORIES = {
      'image' => 'tweet_image',
      'gif'   => 'tweet_gif',
      'video' => 'tweet_video'
    }.freeze

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://api.twitter.com'
      options[:authorize_path] ||= '/oauth/authenticate'
      options[:path_prefix] ||= '/1.1'
      options[:upload_site] = 'https://upload.twitter.com'
      options[:upload_endpoint] = '/media/upload.json'

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
      data && !data["resources"].nil?
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
    def tweet(message, media_ids = nil, api_version = 1)
      if api_version == 2
        tweet_v2(message, media_ids)
      else
        tweet_v1(message, media_ids)
      end
    end

    def tweet_v1(message, media_ids = nil)
      tweet_options = { status: message }
      tweet_options[:media_options] = media_ids.join(',') if media_ids

      post("/statuses/update.json", tweet_options)
    end

    # Destroys the status specified by the required ID parameter. The authenticating user must
    # be the author of the specified status. Returns the destroyed status if successful.
    def delete_tweet(tweet_id, version = 1)
      if version == 2
        delete_tweet_v2(tweet_id)
      else
        delete_tweet_v1(tweet_id)
      end
    end

    def delete_tweet_v1
      post("/statuses/destroy/#{tweet_id}.json")
    end

    # Returns the 20 most recent statuses posted by the authenticating user. It is also possible
    # to request another user's timeline by using the screen_name or user_id parameter. The other
    # users timeline will only be visible if they are not protected, or if the authenticating user's
    # follow request was accepted by the protected user.
    def recent_tweets(options={})
      get("/statuses/user_timeline.json", options)
    end

    # ============================================================================
    # V2 API
    # ============================================================================
    def tweet_v2(message, media_ids = nil)
      tweet_options = { text: message_text }
      tweet_options[:media] = { media_ids: media_ids } if media_ids.any?

      post('https://api.twitter.com/2/tweets', tweet_options.to_json, 'Content-Type' => 'application/json' )
    end

    def delete_tweet_v2(tweet_id)
      delete("https://api.twitter.com/2/tweets/#{tweet_id}")
    end

    def recent_tweets_v2(options = {})
      get('https://api.twitter.com/2/tweets/search/recent', search_options)
    end

    def upload_media(media_url, media_type)
      io = BlueJay::Util.upload_from(media_url)
      tot_chunks = (io.size.to_f/MAX_CHUNK_SIZE).ceil
      media_category = MEDIA_CATEGORIES[media_type]

      init_resp = upload_init(io.size, io.content_type, media_category)
      return init_resp unless init_resp.successful?

      media_id = init_resp.data['media_id']

      segment_index = 0
      until (segment_index + 1) > tot_chunks
        chunk = IO.binread(io, MAX_CHUNK_SIZE, (MAX_CHUNK_SIZE * segment_index))
        append_resp = upload_append(media_id, chunk, segment_index)
        return append_resp unless append_resp.successful?

        segment_index += 1
      end

      upload_finalize(media_id)
    end

    def upload_init(size, media_type, media_category)
      init_opts = {
        command: 'INIT',
        total_bytes: size,
        media_type: media_type,
        media_category: media_category
      }

      with_site(upload_site) do
        post(uri_with_query(upload_endpoint, init_opts))
      end
    end

    def upload_append(media_id, chunk, index)
      with_site(upload_site) do
        post(
         upload_endpoint,
          {
            command: 'APPEND',
            media_id: media_id,
            media_data: Base64.encode64(chunk),
            segment_index: index
          }
        )
      end
    end

    def upload_finalize(media_id)
      with_site(upload_site) do
        post(
          uri_with_query(
            upload_endpoint,
            { command: 'FINALIZE', media_id: media_id }
          )
        )
      end
    end

    def upload_status(media_id)
      with_site(upload_site) do
        get(
          upload_endpoint,
          { command: 'STATUS', media_id: media_id }
        )
      end
    end

    def upload_site
      options[:upload_site]
    end

    def upload_endpoint
      options[:upload_endpoint]
    end

    alias :update :tweet
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
