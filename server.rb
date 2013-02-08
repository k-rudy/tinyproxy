require 'socket'
require 'yaml'

require_relative 'tiny_proxy/request'

require 'pry'

# General server settings
SETTINGS = YAML.load_file("server.yml")

def get_request_from_socket(socket)
  TinyProxy::Request.for_data socket.recv(SETTINGS['request_max_length'])
end

server = TCPServer.new SETTINGS['port']
loop do
  #Thread.start(server.accept) do |client|
  socket = server.accept
  request = get_request_from_socket(socket)
  if request

  end
    socket.puts "Hello !"
    socket.puts "Time is #{Time.now}"
    socket.close
 # end
end
