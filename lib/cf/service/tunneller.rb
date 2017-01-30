require 'cf/service/tunneller/version'
require 'socket'

module Cf
  module Service
    module Tunneller
      LOCAL_ADDRESS = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.getnameinfo.first

      desc 'Cloud Foundry related maintenance tasks'
      namespace :cf do
        namespace :cache do
          desc 'flush the redis cache-service'
          task :flush, [:space] do |t, args|
            tunnel_digger = CloudFoundryTunnelDigger.new(args[:space], 'd3-dashboard', 'p-redis', 'cache-service')
            pid, credentials, local_port = tunnel_digger.dig!
            sleep(3)
            `redis-cli -h #{LOCAL_ADDRESS} -p #{local_port} -a #{credentials['password']} -n 1 "FLUSHDB"`
            puts 'flushed DB 1'
            `kill #{pid}`
          end

          desc 'connect to redis cache-service'
          task :connect, [:space] do |t, args|
            tunnel_digger = CloudFoundryTunnelDigger.new(args[:space], 'd3-dashboard', 'p-redis', 'cache-service')
            pid, credentials, local_port = tunnel_digger.dig!
            connect("redis-cli -h #{LOCAL_ADDRESS} -p #{local_port} -a #{credentials['password']} -n 1", pid)
          end
        end

        namespace :redis do
          desc 'connect to redis odometer-service'
          task :connect, [:space] do |t, args|
            tunnel_digger = CloudFoundryTunnelDigger.new(args[:space], 'd3-dashboard', 'p-redis', 'odometer-service')
            pid, credentials, local_port = tunnel_digger.dig!
            connect("redis-cli -h #{LOCAL_ADDRESS} -p #{local_port} -a #{credentials['password']} -n 1", pid)
          end
        end

        def connect(command, pid)
          puts "opened SSH port forwarding with PID #{pid}, connecting to service..."
          sleep(3)
          system("#{command}; kill #{pid}")
        end
      end
    end
  end
end
