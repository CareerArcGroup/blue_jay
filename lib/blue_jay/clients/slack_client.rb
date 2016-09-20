
module BlueJay
  class SlackClient < Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(webhook_url, options={})
      uri = URI.parse(webhook_url)
      options[:site] ||= uri.to_s.gsub(uri.path, "")
      options[:path_prefix] ||= uri.path

      super(options)
    end

    def share(message, options={})
      post("", merge_default_options(options.merge(text: message)))
    end

    # ============================================================================
    # Options
    # ============================================================================

    def channel
      options[:channel]
    end

    def username
      options[:username]
    end

    def icon_url
      options[:icon_url]
    end

    def icon_emoji
      options[:icon_emoji]
    end

    protected

    def merge_default_options(options={})
      options.merge(
        channel: channel,
        username: username,
        icon_url: icon_url,
        icon_emoji: icon_emoji
      ).select { |_,value| !value.nil? }
    end

    def add_standard_headers(headers={})
      super(headers.merge(
        'Content-Type' => 'application/json',
      ))
    end

    def transform_body(body)
      JSON.unparse(body)
    end

    def response_parser
      BlueJay::SlackParser
    end

  end
end