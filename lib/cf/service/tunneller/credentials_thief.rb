require 'json'

module Cf
  module Service
    module Tunneller
      class CloudFoundryServiceCredentialsThief
        def initialize(space, app, service_type, service_name)
          @app = app
          @space = space
          @service_type = service_type
          @service_name = service_name
        end

        def steal_credentials
          space_guid = `cf curl "/v2/spaces?q=name:#{space}" | jq ".resources[0].metadata.guid" | xargs echo`.strip

          env_raw = `cf curl $(echo $(cf curl "/v2/apps?q=name:#{app}&q=space_guid:#{space_guid}" | jq ".resources[0].metadata.url" | xargs echo)/env)`

          json = JSON.parse(env_raw)
          services = json['system_env_json']['VCAP_SERVICES'][service_type]
          service = services.find { |service| service['name'] == service_name }
          service['credentials'].tap { |cred| cred['host'] = cred['hostname'] unless cred['hostname'].nil? }
        end

        private
        attr_reader :app, :space, :service_type, :service_name
      end
    end
  end
end
