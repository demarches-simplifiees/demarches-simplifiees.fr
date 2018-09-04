CarrierWave.configure do |config|
  # These permissions will make dir and files available only to the user running
  # the servers
  config.permissions = 0664
  config.directory_permissions = 0775

  if ENV['FOG_ENABLED'] == 'enabled'
    config.fog_credentials = {
      provider: 'OpenStack',
      openstack_tenant: ENV['FOG_OPENSTACK_TENANT'],
      openstack_api_key: ENV['FOG_OPENSTACK_API_KEY'],
      openstack_username: ENV['FOG_OPENSTACK_USERNAME'],
      openstack_auth_url: ENV['FOG_OPENSTACK_AUTH_URL'],
      openstack_region: ENV['FOG_OPENSTACK_REGION']
    }
  end

  # This avoids uploaded files from saving to public/ and so
  # they will not be available for public (non-authenticated) downloading
  config.root = Rails.root

  config.cache_dir = Rails.root.join("uploads")

  config.fog_public = true

  config.fog_directory = ENV['FOG_DIRECTORY']
end
