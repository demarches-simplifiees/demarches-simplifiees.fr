ActiveStorage::Service.url_expires_in = 1.hour

# In Rails 5.2, we have to hook at `on_load` on the blob themeselves, which is
# not ideal.
#
# Rails 6 adds support for `.on_load(:active_storage_attachment)`, which is
# cleaner (as it allows to enqueue the virus scan on attachment creation, rather
# than on blob creation).
ActiveSupport.on_load(:active_storage_blob) { include BlobVirusScanner }
