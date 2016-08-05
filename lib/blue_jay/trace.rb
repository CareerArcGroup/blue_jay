
require 'stringio'
require 'securerandom'

module BlueJay
  class Trace
    attr_reader :id, :request, :response
    attr_reader :start_time, :end_time, :duration
    attr_accessor :log

    def initialize
      @id = SecureRandom.uuid
      @start_time = nil
      @end_time = nil
      @duration = 0
      @log = nil
    end

    def self.begin(request)
      new.begin_request(request)
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

    def summary
      "#{request} => #{response}"
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

    def include_log?
      BlueJay.trace? || (response && !response.successful?)
    end
  end
end