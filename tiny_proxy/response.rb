module TinyProxy
  # Simple wraper over HTTPResponse that provides some helper methods
  # forwriting it into the socket and some caching related checks
  #
  class Response

    attr_accessor :response

    # Initializer
    #
    # @param [Net::HTTPResponse] response instance to wrap
    def initialize(response)
      @response = response
    end

    # Checks if the response can be cached
    #
    # @return [true, false] true if can be cached
    def cacheable?
      SETTINGS['cacheable_statuses'].include?(response.code) &&
        SETTINGS['cacheable_types'].include?(response.content_type)
      false
    end

    # Used for writing the response to the socket
    #
    def to_s
      raw_response = "HTTP/1.1 #{response.code} #{response.msg}\n"
      response.each_header {|k, v| raw_response << "#{k}: #{v}\n" }
      raw_response << "\n"
      raw_response << response.body
    end
  end
end
