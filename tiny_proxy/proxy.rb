module TinyProxy
  class Proxy

    attr_accessor :request

    def initializer(request)
      @request = request
    end

    # Serves request
    def serve!

    end
  end
end
