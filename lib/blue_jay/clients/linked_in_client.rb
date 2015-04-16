
module BlueJay
  class LinkedInClient < OAuthClient

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://api.linkedin.com'
      options[:authorize_path] ||= '/uas/oauth/authorize'
      options[:request_token_path] ||= '/uas/oauth/requestToken'
      options[:access_token_path] ||= '/uas/oauth/accessToken'
      options[:path_prefix] ||= '/v1'

      super(options)
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    # ============================================================================
    # Status Methods - These act on Shares
    # ============================================================================

    # Updates the authenticating user's status, also known as sharing.
    # Options:
    #   comment                 Text of share. Share must contain comment and/or (title and submittent_url). Max length 700 bytes
    #   content                 Parent container for the following options
    #     title                 Title of share. Share must contain comment and/or (title and submittent_url). Max length 200 bytes
    #     description           Description of share. Max length 256 bytes
    #     submitted_url         URL for shared content. Invalid without title
    #     submitted_image_url   URL for image of shared content. Invalid without title and submitted_url
    #   visibility              Parent container for visibility code
    #     code                  One of 'anyone' (all members) or 'connections-only'
    #
    def share(options={})
      post('/people/~/shares', options)
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================


    def account_info(*fields)
      field_selector = (fields != nil && fields.any?) ? ":(#{fields.join(',')})" : ''
      get("/people/~#{field_selector}")
    end

    protected

    def add_standard_headers(headers={})
      headers.merge!(
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'x-li-format' => 'json'
        )
      super
    end

    def transform_body(body)
      JSON.unparse(body)
    end

    def response_parser
      BlueJay::LinkedInParser
    end

  end
end
