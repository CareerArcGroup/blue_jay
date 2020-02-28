
require 'stringio'
require 'securerandom'

module BlueJay
  class Trace
    attr_reader :id, :start_time, :end_time, :duration
    attr_accessor :filtered_terms

    FILTER_STRING = "[FILTERED]".freeze
    SNIP_STRING   = "[SNIPPED]".freeze

    def initialize(filtered_terms=[])
      @id = SecureRandom.uuid
      @start_time = nil
      @end_time = nil
      @duration = 0
      @log = nil
      @filtered_terms = filtered_terms
    end

    def self.filter(obj, filtered_terms)
      case obj
      when BlueJay::Response
        obj
      when BlueJay::Request
        BlueJay::Request.new(obj.method, filter(obj.uri, filtered_terms), filter(obj.body, filtered_terms), filter(obj.headers, filtered_terms))
      when URI
        URI.parse(filter(obj.to_s, filtered_terms))
      when Hash
        obj.inject({}) { |m,(k,v)| m.update(k => filter(v, filtered_terms)) }
      else
        value = obj.to_s.dup
        filtered_terms.each do |filtered_term|
          case filtered_term
          when Regexp
            matches = value.to_enum(:scan, filtered_term).map { Regexp.last_match }
            matches.each do |match|
              if match.names.include?("filtered")
                value.gsub!(match[:filtered], FILTER_STRING)
              end
              if match.names.include?("snipped")
                value.gsub!(match[:snipped], SNIP_STRING)
              end
            end
          else
            value.gsub!(filtered_term.to_s, FILTER_STRING)
          end
        end unless (value.nil? || value == "")
        value
      end
    end

    def self.begin(request, filtered_terms=[])
      new(filtered_terms).begin_request(request)
    end

    def begin_request(request)
      @request = request
      @start_time = Time.now
      self
    end

    def complete_request(response)
      @response = response
      @end_time = Time.now
      @duration = @end_time - @start_time
      self
    end

    def request
      @filtered_request ||= filter(@request)
    end

    def response
      @filtered_response ||= filter(@response)
    end

    def summary
      "#{request} => #{response}"
    end

    def log=(value)
      @log = filter(value)
    end

    def log
      @log
    end

    def to_s
      parts = ["#{summary} (#{'%0.2f' % (duration * 1000)}ms)"]
      parts << log if include_log?
      parts.join("\n")
    end

    def inspect
      to_s
    end

    private

    def filter(obj)
      self.class.filter(obj, filtered_terms)
    end

    def include_log?
      BlueJay.trace? || (response && !response.successful?)
    end
  end
end
