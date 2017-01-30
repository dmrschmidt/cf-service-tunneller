require 'cf/service/tunneller/credentials_thief'
require 'socket'

module Cf
  module Service
    module Tunneller
      class Digger
        def initialize(space, app, service_type, service_name)
          @app = app
          @space = space
          @service_type = service_type
          @service_name = service_name
        end

        def dig!
          local_port = random_open_local_port
          puts "digging tunnel to service, using port forwarding with local address #{LOCAL_ADDRESS}:#{local_port}"
          thief = CredentialsThief.new(space, app, service_type, service_name)
          credentials = thief.steal_credentials
          [open_ssh_tunnel(local_port, credentials), credentials, local_port]
        end

        private
        attr_reader :app, :space, :service_type, :service_name

        def open_ssh_tunnel(local_port, credentials)
          tunnel_command = "cf ssh d3-dashboard -L #{LOCAL_ADDRESS}:#{local_port}:#{credentials['host']}:#{credentials['port']} --skip-remote-execution"
          spawn(tunnel_command)
        end

        def random_open_local_port
         socket = Socket.new(:INET, :STREAM, 0)
         socket.bind(Addrinfo.tcp("127.0.0.1", 0))
         socket.local_address.getnameinfo.last.to_i
        end
      end
    end
  end
end
