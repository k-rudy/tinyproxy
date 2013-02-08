require 'net/http'

require_relative 'cache'

module TinyProxy
  class Proxy

    attr_accessor :request, :cache

    def initialize(request)
      @request = request
      @cache = TinyProxy::Cache.new
    end

    # Serves request
    def serve!
      if cache.has? request.uri
        serve_from_cache!
      else
        puts serve_from_remote! "http://tut.by"
      end
    end

    private

    def serve_from_remote!(url, limit=10)
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      # You should choose a better exception.
      raise ArgumentError, 'too many HTTP redirects' if limit == 0

      case response
      when Net::HTTPOK then
        response
        binding.pry
      when Net::HTTPRedirection then
        location = response['location']
        warn "redirected to #{location}"
        serve_from_remote!(location, limit - 1)
      else
        response.value
        binding.pry
      end
    end
  end
end
