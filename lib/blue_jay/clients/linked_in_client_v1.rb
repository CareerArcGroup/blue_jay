
module BlueJay
  class LinkedInClientV1 < OAuthClient

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
      post("/people/~/shares", options)
    end

    # Creates a share on the specified company page (user must be an administrator
    # and must have authorized the client with the rw_company_admin scope)
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
    def company_share(company_id, options={})
      post("/companies/#{company_id}/shares", options)
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    # get general information about the user. optionally pass in an array
    # of specific fields to get a refined list of information...
    def account_info(*fields)
      field_selector = (fields != nil && fields.any?) ? ":(#{fields.join(',')})" : ''
      get("/people/~#{field_selector}")
    end

    # get the list of companies of which the user is an administrator...
    def admin_for_companies
      get("/companies", :"is-company-admin" => true)
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
        'x-li-format' => 'json'
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