require 'objspace'

module TinyProxy
  # Implements proxy server cache.
  #
  # Key ideas:
  # 1) headers are stored seperately from bodies
  #    because it is possible if different URIs contain same response.
  #    It is also more flexible as it is possible to use different
  #    storages for them
  # 2) Due to tight Cache MAX_SIZE limit the following cache strategy was
  #    selected:
  #    If the cache overflow occurs the oldest cached entry is removed
  #    from cache. This is the quickest solution I have found bacause
  #    we don't need extra sorting of the cache content as it is
  #    enough to keep just history of the cached URIs
  #
  #    There's no sense to validate cache using If-Modified-Sinse and Etag
  #    requests because several minutes of intensive surfing will fill
  #    the cache
  #
  class Cache
    class << self

      attr_accessor :headers, :bodies, :uri_history, :space

      # Sinse Rails .megabytes helper is not available we need to
      # define it
      BYTES_IN_MEGABYTE = 1048576

      # Stores response headers and response body digest
      #
      # @key [String] request uri
      # @value [CachedHeader] response without body
      def headers
        @headers ||= {}
      end

      # Response bodies container.
      #
      # @key [String] body digest
      # @value [String] response body
      def bodies
        @bodies ||= {}
      end

      # Contains cached URIs in chronological order
      #
      def uri_history
        @uri_history ||= []
      end

      # Memory used for cache
      #
      def space
        @space ||= 0
      end

      # Checks whether the cache contains URI
      #
      # @param [String] uri - URI to check
      #
      # @return [true, false] true when the uri is in cache
      def has?(uri)
        headers[uri] != nil
      end

      # Adds uri and correspondent response to cache
      #
      # @param [String] uri - request URI
      # @param [Response] response - related response
      def add(uri, response)
        # approximate allocation
        # TODO: add presize space calculation
        needed_space = allocate_space_for(response.header, response.digest, uri,
                                          bodies[response.digest] ? nil : response.body)

        headers[uri] = CachedHeader.new(response.header, response.digest)

        # If body is new - add it, otherwise increment headers counter
        if bodies[response.digest].nil?
          bodies[response.digest] = CachedBody.new(response.body, 1)
        else
          bodies[response.digest].headers_count += 1
        end
        uri_history << uri
        # Updating cache space
        @space = space + needed_space

        puts "Cache space: #{space}. Available: #{space_remaining}"
      end

      # Retrieves cached request by URI
      #
      # @param [String] uri - request URI
      def get(uri)
        header = headers[uri]
        TinyProxy::Response.new(header.header, bodies[header.digest].body)
      end


      private

      # Allocates needed space to store the request in cache
      #
      # @return space needed for arguments
      def allocate_space_for(*args)
        needed_space = space_needed_for(*args)
        while  needed_space > space_remaining do
          cleanup
        end
        needed_space
      end

      # Calculates cache space required to store given arguments
      #
      def space_needed_for(*args)
        args.inject(0) { |sum, arg| sum += ObjectSpace.memsize_of(arg) }
      end

      # Gets the remaining space in cache
      #
      # @return [int] number of bytes remaining
      def space_remaining
        SETTINGS['cache_limit'] * BYTES_IN_MEGABYTE - space
      end

      # Removes first added element from the cache and sets the cache
      # size correspondently
      #
      def cleanup
        uri = uri_history.shift
        header = headers.delete(uri)
        digest = header.digest
        metadata = {uri => header}
        # if there were several headers with the same body we shouldn't
        # delete the body, but decrement headers counter
        if bodies[digest].headers_count > 1
          bodies[digest].headers_count -= 1
          space -= space_needed_for(metadata, uri)
        else
          body = {digest => bodies[digest]}
          space -= space_needed_for(metadata, body, uri)
        end
      end
    end
  end

  class CachedHeader < Struct.new(:header, :digest)
  end

  class CachedBody < Struct.new(:body, :headers_count)
  end
end
