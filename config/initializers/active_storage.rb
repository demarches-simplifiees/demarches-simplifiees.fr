ActiveStorage::Service.url_expires_in = 1.hour

ActiveSupport.on_load(:active_storage_blob) { include BlobVirusScanner }
