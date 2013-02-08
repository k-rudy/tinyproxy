module TinyProxy
  # Some helper methods
  #
  module Helpers
    def get_request_from_socket(socket)
      TinyProxy::Request.for_data socket.recv(SETTINGS['request_max_length'])
    end

    def supported_verb?(verb)
      'GET' == verb
    end

    def not_implemented
      "HTTP/1.1 501 not implemented\r\n\r\n"
    end
  end
end
