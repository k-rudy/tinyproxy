require 'socket'
require 'yaml'

require_relative 'tiny_proxy/helpers'
require_relative 'tiny_proxy/request'

require 'pry'

include TinyProxy::Helpers

# General server settings
SETTINGS = YAML.load_file("server.yml")

server = TCPServer.new SETTINGS['port']
loop do
  #Thread.start(server.accept) do |client|
  socket = server.accept
  request = get_request_from_socket(socket)
  if request
    if supported_verb? request.verb
      socket.puts ok
    else
      socket.puts not_implemented
      socket.puts 'Request type is not supported'
      puts 'Request type is not supported\n' if SETTINGS['debug']
    end
  else
    puts 'Only HTTP requests are supported\n' if SETTINGS['debug']
  end
  socket.close

 # end
end
