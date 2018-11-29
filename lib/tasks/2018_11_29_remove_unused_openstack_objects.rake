namespace :'2018_11_29_remove_unused_openstack_objects' do
  task run: :environment do
    force = (ENV['FORCE'].presence || '0').to_i != 0
    if !force
      rake_puts "Performing dry run, run with FORCE=1 to actually delete target objects"
    end
    fog_credentials = {
      provider: 'OpenStack',
      openstack_tenant: Rails.application.secrets.fog[:openstack_tenant],
      openstack_api_key: Rails.application.secrets.fog[:openstack_api_key],
      openstack_username: Rails.application.secrets.fog[:openstack_username],
      openstack_auth_url: Rails.application.secrets.fog[:openstack_auth_url],
      openstack_region: Rails.application.secrets.fog[:openstack_region],
      openstack_identity_api_version: Rails.application.secrets.fog[:oopenstack_identity_api_version]
    }
    connection = Fog::Storage.new(fog_credentials)
    directory = connection.directories.get(ENV['FOG_ACTIVESTORAGE_DIRECTORY'])

    bar = RakeProgressbar.new(directory.count.to_i)

    directory.files.each do |file|
      if !ActiveStorage::Blob.exists?(key: file.key)
        rake_puts "Remove unused object #{file.key}"
        if force
          file.destroy
        end
      end

      bar.inc
    end

    bar.finished
  end
end
