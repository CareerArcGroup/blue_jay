module BlueJay
  class LinkedInClientV2 < OAuth2Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://api.linkedin.com'
      options[:authorize_url] ||= 'https://www.linkedin.com/oauth/v2/authorization'
      options[:token_url]     ||= 'https://www.linkedin.com/oauth/v2/accessToken'
      options[:path_prefix] ||= '/v2'
      options[:api_version] ||= '202211'

      super(options)
    end

    def authorize_url(redirect_uri, options={})
      super(redirect_uri, options.merge(scope: options[:scope].join(' ')))
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    def api_version
      options[:api_version]
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    # get general information about the user. optionally pass in an array
    # of specific fields to get a refined list of information...
    def account_info(*fields)
      get("/me#{field_selector(fields)}")
    end

    # get the list of companies of which the user is an administrator...
    def admin_for_companies
      get("/organizationalEntityAcls?q=roleAssignee&role=ADMINISTRATOR&state=APPROVED&count=100")
    end

    # get general information about a company. optionally pass in an array
    # of specific fields to get a refined list of information...
    def company_info(company_id, *fields)
      get("/organizations/#{company_id}#{field_selector(fields)}")
    end

    # ===========================================================================
    # Videos
    # ============================================================================

    def upload_video(action, options={})
      headers = { 'LinkedIn-Version' =>  api_version }

      post("/videos?action=#{action}", options, headers)
    end

    def video_initialize(options={})
      upload_video('initializeUpload', options)
    end

    def video_finalize(options={})
      upload_video('finalizeUpload', options)
    end

    def video(video_urn)
      headers = {
        'X-Restli-Protocol-Version' => nil,
        'LinkedIn-Version' => api_version
      }

       get("/videos/#{video_urn}", {}, headers)
    end

    # ============================================================================
    # images
    # ============================================================================

    def upload_image(action, options={})
      headers = { 'LinkedIn-Version' =>  api_version }

      post("https://api.linkedin.com/rest/images?action=#{action}", options, headers)
    end

    def image_initialize(options={})
      upload_image('initializeUpload', options)
    end

    def upload(url, file)
      put(url, file)
    end

    def image(image_urn)
      headers = {
        'X-Restli-Protocol-Version' => nil,
        'LinkedIn-Version' => api_version
      }

       get("https://api.linkedin.com/rest/images/#{image_urn}", {}, headers)
    end

    def li_post(options={})
      headers = { 'LinkedIn-Version' => api_version }

      post("https://api.linkedin.com/rest/posts", options, headers)
    end

    protected

    def uri_with_query(url, query={})
      uri = super
      # LinkedIn with X-Restli-Protocol-Version 2.0.0 requires these characters
      # to be unescaped
      uri.gsub('%28', '(').gsub('%29', ')').gsub('%2C', ',')
    end

    def field_selector(fields)
      (fields != nil && fields.any?) ? "?projection=(#{fields.join(',')})" : ''
    end

    def add_standard_headers(headers={})
      additional_headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'X-Restli-Protocol-Version' => '2.0.0'
      }

      super(additional_headers.merge(headers))
    end

    def transform_body(body)
      JSON.unparse(body)
    end

    def response_parser
      BlueJay::LinkedInParser
    end

  end
end
