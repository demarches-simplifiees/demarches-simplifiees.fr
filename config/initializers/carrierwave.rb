CarrierWave.configure do |config|
  # These permissions will make dir and files available only to the user running
  # the servers
  config.permissions = 0664
  config.directory_permissions = 0775

  if ENV['FOG_ENABLED'] == 'enabled'
    config.fog_credentials = {
      provider: 'OpenStack',
      openstack_tenant: Rails.application.secrets.fog[:openstack_tenant],
      openstack_api_key: Rails.application.secrets.fog[:openstack_api_key],
      openstack_username: Rails.application.secrets.fog[:openstack_username],
      openstack_auth_url: Rails.application.secrets.fog[:openstack_auth_url],
      openstack_region: Rails.application.secrets.fog[:openstack_region]
    }
  end

  # This avoids uploaded files from saving to public/ and so
  # they will not be available for public (non-authenticated) downloading
  config.root = Rails.root

  config.cache_dir = Rails.root.join("uploads")

  config.fog_public = true

  config.fog_directory = Rails.application.secrets.fog[:directory]
end
