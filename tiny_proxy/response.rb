require 'digest/md5'

module TinyProxy
  # Simple wraper over HTTPResponse that provides some helper methods
  # forwriting it into the socket and some caching related checks
  #
  class Response

    attr_accessor :header, :body, :code, :msg, :digest

    # Initializer
    #
    # @param [Hash] header
    # @param [String] body
    # @param [String] code
    # @param [String] msg - response header message
    def initialize(header, body, code, msg)
      @header = header
      @body = body
      @code = code
      @msg = msg
    end

    # Checks if the response can be cached
    #
    # @return [true, false] true if can be cached
    def cacheable?
      SETTINGS['cacheable_statuses'].include?(code) &&
        SETTINGS['cacheable_types'].include?(content_type)
    end

    # Used for writing the response to the socket
    #
    def to_s
      raw_response = "HTTP/1.1 #{code} #{msg}\n"
      header.each {|k, v| raw_response << "#{k}: #{v.first}\n" }
      raw_response << "\n"
      raw_response << body
    end

    # Lazily initialized response body digest
    # Response etag wasn't considered as the right digest because not
    # all responses contain it
    #
    def digest
      @digest ||= Digest::MD5.hexdigest(body)
    end

    # Gets content-type from header omitting charset info
    #
    def content_type
      header['content-type'] && header['content-type'].first.split(';').first
    end
  end
end
