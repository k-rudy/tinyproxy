require 'net/http'

require_relative 'cache'
require_relative 'response'

module TinyProxy
  class Proxy

    attr_accessor :request

    def initialize(request)
      @request = request
    end

    # Serves request either from cache or from remote location
    #
    def serve!
      if TinyProxy::Cache.has? request.uri
        serve_from_cache!
      else
        serve_from_remote!
      end
    end

    private

    # Performs HTTP request
    # If the response is cacheable then adds it to the cache
    #
    # @return [TinyProxy::Response] wrapped response
    def serve_from_remote!
      uri = URI(request.uri)
      http_response = Net::HTTP.get_response(uri)
      response = wrap_response(http_response)
      if response.cacheable?
        # TODO: Add caching
      end
      response
    end

    def serve_from_cache
      #TODO: implement retrieval from cache logic
    end

    # Wraps HTTPResponse with TinyProxy::Response
    #
    def wrap_response(response)
      TinyProxy::Response.new response
    end
  end
end
