
module BlueJay
  class LinkedInClient < Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://api.linkedin.com'
      options[:authorize_path] ||= '/uas/oauth/authorize'
      options[:request_token_path] ||= '/uas/oauth/requestToken'
      options[:access_token_path] ||= '/uas/oauth/accessToken'
      options[:path_prefix] ||= 'v1'
      
      super(options)
    end

    def connected?
      authorized?
    end

    def authorized?
      data = rate_limit_status
      data && data["resources"] && data["resources"].count > 0
    end

    # ============================================================================
    # Status Methods - These act on Shares
    # ============================================================================

    # Updates the authenticating user's status, also known as sharing.
    # Options:
    #   comment               Text of share. Share must contain comment and/or (title and submittent_url). Max length 700 bytes
    #   title                 Title of share. Share must contain comment and/or (title and submittent_url). Max length 200 bytes
    #   description           Description of share. Max length 256 bytes
    #   submitted_url         URL for shared content. Invalid without title
    #   submitted_image_url   URL for image of shared content. Invalid without title and submitted_url
    #   visibility            One of :anyone (all members) or :connections_only
    #
    def share(options={})
      post('/people/~/shares', options)
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    # Returns an HTTP 200 OK response code and a representation of the requesting
    # user if authentication was successful; returns a 401 status code and an error
    # message if not. Use this method to test if supplied user credentials are valid.
    def account_info
      get('/people/~')
    end

    # Returns the remaining number of API requests available to the requesting user
    # before the API limit is reached for the current hour. Calls to rate_limit_status
    # do not count against the rate limit. If authentication credentials are provided,
    # the rate limit status for the authenticating user is returned. Otherwise, the rate
    # limit status for the requesting IP address is returned.
    def rate_limit_status
      get('/application/rate_limit_status.json')
    end

  end
end
