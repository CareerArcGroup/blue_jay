require 'logger'

module BlueJay
  class LoggerWrapper
    def initialize(logger)
      @logger = logger
    end

    def <<(message)
      @logger << message if @logger.debug?
    end

    def method_missing(sym, *args, &block)
      @logger.send sym, *args, &block
    end
  end
end
