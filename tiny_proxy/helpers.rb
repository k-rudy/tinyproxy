
module TinyProxy
  # Some helper methods
  #
  module Helpers
    def get_request_from_socket(socket)
      data = socket.recv(SETTINGS['request_max_length'])
      TinyProxy::Request.for_data(data) if data && data.start_with?('GET')
    end

    def not_implemented
      "HTTP/1.1 501 not implemented\r\n\r\n"
    end
  end
end
