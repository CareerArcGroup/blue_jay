
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

    # ============================================================================
    # Status Methods - These act on Shares
    # ============================================================================

    def share(options={})
      post("/ugcPosts", options)
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    # get general information about the user. optionally pass in an array
    # of specific fields to get a refined list of information...
    def account_info(*fields)
      field_selector = (fields != nil && fields.any?) ? "?projection=(#{fields.join(',')})" : ''
      get("/me#{field_selector}")
    end

    # get the list of companies of which the user is an administrator...
    def admin_for_companies
      get("/companies", :"is-company-admin" => true, :"count" => 100)
    end

    # get general information about a company. optionally pass in an array
    # of specific fields to get a refined list of information...
    def company_info(company_id, *fields)
      field_selector = (fields != nil && fields.any?) ? ":(#{fields.join(',')})" : ''
      get("/companies/#{company_id}#{field_selector}")
    end

    protected

    def add_standard_headers(headers={})
      super(headers.merge(
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'X-Restli-Protocol-Version' => '2.0.0'
      ))
    end

    def transform_body(body)
      JSON.unparse(body)
    end

    def response_parser
      BlueJay::LinkedInParser
    end

  end
end
