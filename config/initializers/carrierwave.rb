module Fog
  module ServicesMixin
    private

    def require_service_provider_library(service, provider)
      # Monkey patch to fix https://github.com/fog/fog/issues/4014

      # This method exists in fog to load legacy providers that have not yet been extracted to
      # their own gem.
      # fog-openstack has been extracted to its own gem and does not need this method.
      # Furthermore, fog-openstack has recently been refactored in a way that breaks this method.
      #
      # Therefore, until either fog or fog-openstack fixes the problem, we have to neuter the method.
    end
  end
end

CarrierWave.configure do |config|
  # These permissions will make dir and files available only to the user running
  # the servers
  config.permissions = 0664
  config.directory_permissions = 0775

  config.fog_provider = 'fog/openstack'

  if ENV['FOG_ENABLED'] == 'enabled'
    config.fog_credentials = {
      provider: 'OpenStack',
      openstack_tenant: Rails.application.secrets.fog[:openstack_tenant],
      openstack_api_key: Rails.application.secrets.fog[:openstack_api_key],
      openstack_username: Rails.application.secrets.fog[:openstack_username],
      openstack_auth_url: Rails.application.secrets.fog[:openstack_auth_url],
      openstack_region: Rails.application.secrets.fog[:openstack_region],
      openstack_identity_api_version: Rails.application.secrets.fog[:oopenstack_identity_api_version]
    }
  end

  # This avoids uploaded files from saving to public/ and so
  # they will not be available for public (non-authenticated) downloading
  config.root = Rails.root

  config.cache_dir = Rails.root.join("uploads")

  config.fog_public = true

  config.fog_directory = Rails.application.secrets.fog[:directory]
end
