require 'socket'
require 'yaml'

require_relative 'tiny_proxy/proxy'
require_relative 'tiny_proxy/helpers'
require_relative 'tiny_proxy/request'

require 'pry'

include TinyProxy::Helpers

# General server settings
SETTINGS = YAML.load_file("server.yml")

server = TCPServer.new SETTINGS['port']
loop do
  Thread.start(server.accept) do |socket|
    request = get_request_from_socket(socket)
    if request
      proxy = TinyProxy::Proxy.new(request)
      response = proxy.serve!
      begin
        socket.puts response
      rescue Errno::EPIPE => e
        puts "Socket write error: #{e.message}"
      end
    else
      puts 'Only GET http requests are supported' if SETTINGS['debug']
    end
    socket.close
  end
end
