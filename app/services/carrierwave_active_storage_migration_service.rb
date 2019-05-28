class CarrierwaveActiveStorageMigrationService
  def ensure_openstack_copy_possible!(uploader)
    ensure_active_storage_openstack!
    ensure_carrierwave_openstack!(uploader)
    ensure_active_storage_and_carrierwave_credetials_match(uploader)
  end

  def ensure_active_storage_openstack!
    # If we manage to get the client, it means that ActiveStorage is on OpenStack
    openstack_client!
  end

  def openstack_client!
    @openstack_client ||= active_storage_openstack_client!
  end

  def active_storage_openstack_client!
    service = ActiveStorage::Blob.service

    if defined?(ActiveStorage::Service::DsProxyService) &&
        service.is_a?(ActiveStorage::Service::DsProxyService)
      service = service.wrapped
    end

    if !defined?(ActiveStorage::Service::OpenStackService) ||
        !service.is_a?(ActiveStorage::Service::OpenStackService)
      raise StandardError, 'ActiveStorage must be backed by OpenStack'
    end

    service.client
  end

  def ensure_carrierwave_openstack!(uploader)
    storage = fog_client!(uploader)

    if !defined?(Fog::OpenStack::Storage::Real) ||
        !storage.is_a?(Fog::OpenStack::Storage::Real)
      raise StandardError, 'Carrierwave must be backed by OpenStack'
    end
  end

  def fog_client!(uploader)
    storage = uploader.new.send(:storage)

    if !defined?(CarrierWave::Storage::Fog) ||
        !storage.is_a?(CarrierWave::Storage::Fog)
      raise StandardError, 'Carrierwave must be backed by a Fog provider'
    end

    storage.connection
  end

  # OpenStack Swift's COPY object command works across different buckets, but they still need
  # to be on the same object store. This method tries to ensure that Carrierwave and ActiveStorage
  # are indeed pointing to the same Swift store.
  def ensure_active_storage_and_carrierwave_credetials_match(uploader)
    auth_keys = [
      :openstack_tenant,
      :openstack_api_key,
      :openstack_username,
      :openstack_region,
      :openstack_management_url
    ]

    active_storage_creds = openstack_client!.credentials.slice(*auth_keys)
    carrierwave_creds = fog_client!(uploader).credentials.slice(*auth_keys)

    if active_storage_creds != carrierwave_creds
      raise StandardError, "Active Storage and Carrierwave credentials must match"
    end
  end

  # If identify is true, force ActiveStorage to examine the beginning of the file
  # to determine its MIME type. This identification does not happen immediately,
  # but when the first attachment that references this blob is created.
  def make_blob(uploader, created_at, filename: nil, identify: false)
    content_type = uploader.content_type
    identified = content_type.present? && !identify

    ActiveStorage::Blob.create(
      filename: filename || uploader.filename,
      content_type: uploader.content_type,
      byte_size: uploader.size,
      checksum: checksum(uploader),
      created_at: created_at,
      metadata: { identified: identified, virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )
  end

  def checksum(uploader)
    hex_to_base64(uploader.file.send(:file).etag)
  end

  def hex_to_base64(hexdigest)
    [[hexdigest].pack("H*")].pack("m0")
  end

  def copy_from_carrierwave_to_active_storage!(source_name, blob)
    openstack_client!.copy_object(
      carrierwave_container_name,
      source_name,
      active_storage_container_name,
      blob.key
    )

    fix_content_type(blob)
  end

  def carrierwave_container_name
    Rails.application.secrets.fog[:directory]
  end

  def active_storage_container_name
    ENV['FOG_ACTIVESTORAGE_DIRECTORY']
  end

  def delete_from_active_storage!(blob)
    openstack_client!.delete_object(
      active_storage_container_name,
      blob.key
    )
  end

  # Before calling this method, you must make sure the file has been uploaded for the blob.
  # Otherwise, this method might fail if it needs to read the beginning of the file to
  # update the blob’s MIME type.
  def make_attachment(model, attachment_name, blob)
    attachment = ActiveStorage::Attachment.create(
      name: attachment_name,
      record_type: model.class.base_class.name,
      record_id: model.id,
      blob: blob,
      created_at: model.updated_at.iso8601
    )

    # Making the attachment may have triggerred MIME type auto detection on the blob,
    # so we make sure to sync that potentially new MIME type to the object in OpenStack
    fix_content_type(blob)

    attachment
  end

  def fix_content_type(blob)
    # In OpenStack, ActiveStorage cannot inject the MIME type on the fly during direct
    # download. Instead, the MIME type needs to be stored statically on the file object
    # in OpenStack. This is what this call does.
    blob.service.change_content_type(blob.key, blob.content_type)
  end
end
