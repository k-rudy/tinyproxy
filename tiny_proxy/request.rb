require 'active_support'

module TinyProxy
  class Request

    attr_accessor :verb, :uri, :options

    class << self

      # Extracts Request object from socket raw data
      #
      # @note:
      #   At the moment only HTTP requests are supported
      #
      # @param [String] data - data to parse
      #
      # @return [nil, Request] - if this sis a valid http request then
      #   it requrns instantiated request object, nil - otherwise
      def for_data(data)
        puts data if SETTINGS['debug']
        tokens = data.split("\r\n")
        verb, path, head = tokens[0].split(' ')
        if http? head
          options = tokens[1..-1].inject({}) do |hash, row|
            key, value = row.split(': ')
            hash[key] = value
            hash
          end
          host = options.delete('Host')
          uri = "http://#{host}#{path}"
          new(verb, uri, options)
        end
      end

      private

      # Checks whether the request is a http request
      #
      def http?(head)
        head && head.start_with?('HTTP')
      end
    end

    # Initializer
    #
    # @param [String] verb - HTTP verb (GET, POST etc.)
    # @param [String] uri - uri
    # @param [Hash] options - remaining http request options
    #
    def initialize(verb, uri, options)
      @verb = verb
      @uri = uri
      @options
    end
  end
end
