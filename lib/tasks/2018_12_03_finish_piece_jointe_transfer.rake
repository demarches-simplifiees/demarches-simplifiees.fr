namespace :'2018_12_03_finish_piece_jointe_transfer' do
  task run: :environment do
    Class.new do
      def run
        notify_dry_run
        fix_openstack_mime_types
        remove_unused_openstack_objects
        notify_dry_run
      end

      def notify_dry_run
        if !force?
          rake_puts "Dry run, run with FORCE=1 to actually perform changes"
        end
      end

      def force?
        if !defined? @force
          @force = (ENV['FORCE'].presence || '0').to_i != 0
        end

        @force
      end

      def verbose?
        if !defined? @verbose
          @verbose = (ENV['VERBOSE'].presence || '0').to_i != 0
        end

        @verbose
      end

      def new_pjs
        if !defined? @new_pjs
          fog_credentials = {
            provider: 'OpenStack',
            openstack_tenant: Rails.application.secrets.fog[:openstack_tenant],
            openstack_api_key: Rails.application.secrets.fog[:openstack_api_key],
            openstack_username: Rails.application.secrets.fog[:openstack_username],
            openstack_auth_url: Rails.application.secrets.fog[:openstack_auth_url],
            openstack_region: Rails.application.secrets.fog[:openstack_region],
            openstack_identity_api_version: Rails.application.secrets.fog[:oopenstack_identity_api_version]
          }
          new_pj_storage = Fog::Storage.new(fog_credentials)
          @new_pjs = new_pj_storage.directories.get(ENV['FOG_ACTIVESTORAGE_DIRECTORY'])
        end

        @new_pjs
      end

      # For OpenStack, the content type cannot be forced dynamically from a direct download URL.
      #
      # The ActiveStorage-OpenStack adapter works around this by monkey patching ActiveStorage
      # to statically set the correct MIME type on each OpenStack object.
      #
      # However, for objects that have been migrated from another storage, the content-type might
      # be wrong, so we manually fix it.
      def fix_openstack_mime_types
        if !ActiveStorage::Blob.service.respond_to?(:change_content_type)
          rake_puts "Not running on openstack, not fixing MIME types"
          return
        end
        rake_puts "Fix MIME types"

        bar = RakeProgressbar.new(ActiveStorage::Blob.count)
        failed_keys = []
        updated_keys = []
        ActiveStorage::Blob.find_each do |blob|
          if blob.identified? && blob.content_type.present?
            updated_keys.push(blob.key)
            if force?
              if !blob.service.change_content_type(blob.key, blob.content_type)
                failed_keys.push(blob.key)
              end
            end
          end
          bar.inc
        end
        bar.finished

        if verbose?
          rake_puts "Updated MIME Type for #{updated_keys.count} keys\n#{updated_keys.join(', ')}"
        end
        if failed_keys.present?
          rake_puts "failed to update #{failed_keys.count} keys (dangling blob?)\n#{failed_keys.join(', ')}"
        end
      end

      # Garbage collect objects that might have been removed in the meantime
      def remove_unused_openstack_objects
        rake_puts "Remove unused files"

        bar = RakeProgressbar.new(new_pjs.count.to_i)
        removed_keys = []
        new_pjs.files.each do |file|
          if !ActiveStorage::Blob.exists?(key: file.key)
            removed_keys.push(file.key)
            if force?
              file.destroy
            end
          end

          bar.inc
        end
        bar.finished

        if verbose?
          rake_puts "Removed #{removed_keys.count} unused objects\n#{removed_keys.join(', ')}"
        end
      end
    end.new.run
  end
end
