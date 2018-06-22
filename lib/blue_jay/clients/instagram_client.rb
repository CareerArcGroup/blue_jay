
module BlueJay
  class InstagramClient < OAuth2Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site]          ||= 'https://api.instagram.com'
      options[:authorize_url] ||= 'https://api.instagram.com/oauth/authorize'
      options[:token_url]     ||= 'https://api.instagram.com/oauth/access_token'
      options[:path_prefix]   ||= '/v1'
      options[:token_mode]    ||= :query

      super(options)
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    # ============================================================================
    # Users methods
    # ============================================================================

    # Get information about the owner of the access token
    def account_info
      get("/users/self")
    end

    # Get the most recent media published by the owner of the access_token.
    # Options:
    #   max_id               Return media earlier than this max_id
    #   min_id               Return media later than this min_id
    #   count                Count of media to return
    #
    def recent_media(options={})
      get("/users/self/media/recent", options)
    end

    # ============================================================================
    # Media Methods
    # ============================================================================

    # Search for recent media in a given area
    # Options:
    #   lat                  Latitude of the center search coordinate. If used, lng is required.
    #   lng                  Longitude of the center search coordinate. If used, lat is required.
    #   distance             Search radius in meters. Default is 1km (distance=1000), max distance is 5km.
    #
    def search(options={})
      get("/media/search", options)
    end

    # ============================================================================
    # Comments
    # ============================================================================

    # Get a list of recent comments on your media object.
    def comments(media_id)
      get("/media/#{media_id}/comments")
    end

    # ============================================================================
    # Tags
    # ============================================================================

    # Get information about the given tag name.
    def tag(tag_name)
      get("/tags/#{tag_name}")
    end

    # Search for tags by name.
    #   query: A valid tag name without a leading "#" (e.g. "snowy", "nofilter")
    #
    def tags(query)
      get("/tags/search", query: query)
    end

    # Get a list of recently tagged media
    # Options:
    #   max_tag_id           Return media earlier than this max_id
    #   min_tag_id           Return media later than this min_id
    #   count                Count of media to return
    #
    def media_with_tag(tag_name, options={})
      get("/tags/#{tag_name}/media/recent", options)
    end

    # ============================================================================
    # Locations
    # ============================================================================

    # Get information about a location
    def location(location_id)
      get("/locations/#{location_id}")
    end

    # Search for locations by a geographic coordiante.
    # Options:
    #   lat                  Latitude of the center search coordinate.  If used, lng is required.
    #   lng                  Longitude of the center search coordinate.  If used, lat is required.
    #   distance             Search radius in meters.  Default is 500m (distance=500), max distance is 750m.
    #   facebook_places_id   Returns a location mapped off of a Facebook places ID.  If used, lat and lng are not required.
    #
    def locations(options={})
      get("/locations/search")
    end

    # Get a list of recent media objects from a given location.
    # Options:
    #   max_tag_id           Return media earlier than this max_id
    #   min_tag_id           Return media later than this min_id
    #
    def media_in_location(location_id, options={})
      get("/locations/#{location_id}/media/recent", options)
    end

    protected

    def get(path, params={})
      params[:access_token] ||= token
      super
    end

    def add_standard_headers(headers={})
      super(headers.merge(
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      ))
    end

    def transform_body(body)
      JSON.unparse(body)
    end

    def response_parser
      BlueJay::InstagramParser
    end
  end
end
