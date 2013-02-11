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
      uri = URI.parse(request.uri)

      req = Net::HTTP::Get.new(uri.path)
      req.initialize_http_header(request.options)
      http_response = Net::HTTP.new(uri.host, uri.port).start do |http|
        http.request(req)
      end

      response = wrap_response(http_response)
      if response.cacheable?
        puts "\nCaching '#{request.uri}'" if SETTINGS['debug']
        TinyProxy::Cache.add(request.uri, response)
      end
      response
    end

    # Gets the cached response
    #
    def serve_from_cache
      puts "Served from cache '#{request.uri}'" if SETTINGS ['debug']
      TinyProxy::Cache.get(request.uri)
    end

    # Wraps HTTPResponse with TinyProxy::Response
    #
    def wrap_response(response)
      TinyProxy::Response.new(response.to_hash,
                              response.body,
                              response.code,
                              response.msg)
    end
  end
end
