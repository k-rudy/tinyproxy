require_relative 'space'

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
  # Cache size is evaluated with certain approximation
  #
  class Cache

    class << self
      include Space

      # Sinse Rails .megabytes helper is not available we need to
      # define it
      BYTES_IN_MEGABYTE = 1048576

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
        header = CachedHeader.new(response.header, response.code,
                                  response.msg, response.digest)
        body = bodies[response.digest] || CachedBody.new(response.body, 1)

        needed_space = ensure_space(uri, header, body)

        # Adding structures to cache
        headers[uri] = header
        save_body(response.digest, body)
        uri_history << uri

        # Updating cache size
        @size = size + needed_space

        puts "Cache size: #{size}. Available: #{space_remaining}\n\n" if ::SETTINGS['debug']
      end

      # Retrieves cached request by URI
      #
      # @param [String] uri - request URI
      def get(uri)
        header = headers[uri]
        TinyProxy::Response.new(header.header, bodies[header.digest].body,
                                header.code, header.msg, )
      end

      private

      # Memory used for cache in bytes
      #
      def size
        @size ||= 0
      end

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

      private

      # If body is new - add it, otherwise increment headers counter
      #
      def save_body(digest, body)
        if bodies[digest].nil?
          bodies[digest] = body
        else
          puts "Response exists in cache. Incrementing counter" if ::SETTINGS['debug']
          bodies[digest].headers_count += 1
        end
      end

      # Gets the cache entry size in bytes.
      # total size cosists of double URI, cache header size and body
      # size
      #
      # @param [String] uri
      # @param [CachedHeader] header
      # @param [CachedBody] body - optional
      #
      # @return [int] - size in bytes
      def cache_entry_size(uri, header, body = nil)
        space = space_needed_for(uri, uri) + header.size
        if body && bodies[header.digest].nil?
          space += (space_needed_for(header.digest) + body.size)
        end
        space
      end

      # Allocates space needed to store response.
      # If the body with the same digest already exists space is not
      # allocated for it
      #
      # @return [int] needed space in bytes
      def ensure_space(uri, header, body)
        allocate(cache_entry_size(uri, header, body))
      end

      # Allocates needed space to store the request in cache
      #
      # @return space needed for arguments
      def allocate(space)
        while space > space_remaining do
          cleanup
        end
        space
      end

      # Gets the remaining space in cache
      #
      # @return [int] number of bytes remaining
      def space_remaining
        ::SETTINGS['cache_limit'] * BYTES_IN_MEGABYTE - size
      end

      # Removes first added element from the cache and sets the cache
      # size correspondently
      #
      def cleanup
        uri = uri_history.shift

        puts "Removing '#{uri}' from cache" if ::SETTINGS['debug']

        header = headers.delete(uri)
        digest = header.digest

        # if there were several headers with the same body we shouldn't
        # delete the body, but decrement headers counter
        if bodies[digest].headers_count > 1
          puts 'Cache body is used by other requests. Decrementing counter' if ::SETTINGS['debug']
          bodies[digest].headers_count -= 1
          allocated_space = cache_entry_size(uri, header)
        else
          body = bodies.delete(digest)
          allocated_space = cache_entry_size(uri, header, body)
        end
        @size = size - allocated_space
        puts "Allocated space: #{allocated_space}" if ::SETTINGS['debug']
      end
    end
  end

  # Cached header structure
  #
  class CachedHeader < Struct.new(:header, :code, :msg, :digest)
    include Space

    # Header size in bytes
    def size
      space_needed_for(header, code, msg, digest)
    end
  end

  # Cached body structure
  #
  class CachedBody < Struct.new(:body, :headers_count)
    include Space

    # Body size in bytes
    def size
      space_needed_for(body, headers_count)
    end
  end
end
