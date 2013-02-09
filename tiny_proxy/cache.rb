module TinyProxy
  class Cache
    class << self

      def has?(uri)
        false
      end

      def add(request, response)
        #TODO
      end
    end
  end
end
