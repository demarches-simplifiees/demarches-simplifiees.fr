namespace :'2018_11_29_fix_openstack_mime_types' do
  task run: :environment do
    # For OpenStack, the content type cannot be forced dynamically from a direct download URL.
    #
    # The ActiveStorage-OpenStack adapter works around this by monkey patching ActiveStorage
    # to statically set the correct MIME type on each OpenStack object.
    #
    # However, for objects that have been migrated from another storage, the content-type might
    # be wrong, so we manually fix it.

    bar = RakeProgressbar.new(ActiveStorage::Blob.count)

    ActiveStorage::Blob.find_each.with_index do |blob, i|
      if !blob.service.respond_to?(:change_content_type)
        bar.finished
        fail "Not running on openstack"
      end
      if blob.identified? && blob.content_type.present? &&
          !blob.service.change_content_type(blob.key, blob.content_type)
        rake_puts "failed to update #{blob.key} (dangling blob?)"
      end

      bar.inc
    end

    bar.finished
  end
end
