namespace :'2018_12_03_finish_piece_jointe_transfer' do
  task run: :environment do
    Class.new do
      def run
        notify_dry_run
        refresh_outdated_files
        remove_unused_openstack_objects
        fix_openstack_mime_types
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

      def old_pj_adapter
        raise NotImplementedError, "No connection adapter for old PJ storage"
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
            openstack_identity_api_version: Rails.application.secrets.fog[:openstack_identity_api_version]
          }
          new_pj_storage = Fog::Storage.new(fog_credentials)
          @new_pjs = new_pj_storage.directories.get(ENV['FOG_ACTIVESTORAGE_DIRECTORY'])
        end

        @new_pjs
      end

      # After the initial bulk transfer, but before ActiveStorage is switched to the new storage,
      # there is a window where new attachments can be added to the old storage.
      #
      # This task ports them to the new storage after the switch, while being careful not to
      # overwrite attachments that may have changed in the new storage after the switch.
      def refresh_outdated_files
        refreshed_keys = []
        old_pj_adapter.session do |old_pjs|
          rake_puts "List old PJs"
          old_pj_listing = old_pjs.list_prefixed('')

          rake_puts "List new PJs"
          new_pj_listing = {}
          progress = ProgressReport.new(new_pjs.count.to_i)
          new_pjs.files.each do |f|
            new_pj_listing[f.key] = f.last_modified.in_time_zone
            progress.inc
          end
          progress.finish

          rake_puts "Refresh outdated attachments"
          progress = ProgressReport.new(old_pj_listing.count)
          old_pj_listing.each do |key, old_pj_last_modified|
            new_pj_last_modified = new_pj_listing[key]

            if new_pj_last_modified.nil? || new_pj_last_modified < old_pj_last_modified
              # Looks like we need to refresh  this PJ.
              # Fetch fresh metadata to avoid overwriting a last-minute change
              new_pj_metadata = new_pjs.files.head(key)
              refresh_needed = new_pj_metadata.nil?
              if !refresh_needed
                new_pj_last_modified = new_pj_metadata.last_modified.in_time_zone
                refresh_needed = new_pj_last_modified < old_pj_last_modified
              end
            end

            if refresh_needed
              refreshed_keys.push(key)
              if force?
                file = Tempfile.new(key)
                file.binmode
                old_pjs.download(key) do |chunk|
                  file.write(chunk)
                end
                file.rewind
                new_pjs.files.create(
                  :key    => key,
                  :body   => file,
                  :public => false
                )
                file.close
                file.unlink
              end
            end
            progress.inc
          end
          progress.finish
        end

        if verbose?
          rake_puts "Refreshed #{refreshed_keys.count} attachments\n#{refreshed_keys.join(', ')}"
        end
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

        progress = ProgressReport.new(new_pjs.count.to_i)
        failed_keys = []
        updated_keys = []
        new_pjs.files.each do |file|
          blob = ActiveStorage::Blob.find_by(key: file.key)
          if blob.nil?
            failed_keys.push(file.key)
          elsif blob.identified? && blob.content_type.present?
            updated_keys.push(file.key)
            if force?
              if !blob.service.change_content_type(file.key, blob.content_type)
                failed_keys.push(file.key)
              end
            end
          end
          progress.inc
        end
        progress.finish

        if verbose?
          rake_puts "Updated MIME Type for #{updated_keys.count} keys\n#{updated_keys.join(', ')}"
        end
        if failed_keys.present?
          rake_puts "failed to update #{failed_keys.count} keys\n#{failed_keys.join(', ')}"
        end
      end

      # Garbage collect objects that might have been removed in the meantime
      def remove_unused_openstack_objects
        rake_puts "Remove unused files"

        progress = ProgressReport.new(new_pjs.count.to_i)
        removed_keys = []
        new_pjs.files.each do |file|
          if !ActiveStorage::Blob.exists?(key: file.key)
            removed_keys.push(file.key)
            if force?
              file.destroy
            end
          end

          progress.inc
        end
        progress.finish

        if verbose?
          rake_puts "Removed #{removed_keys.count} unused objects\n#{removed_keys.join(', ')}"
        end
      end
    end.new.run
  end
end
