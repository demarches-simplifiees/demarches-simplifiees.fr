ActiveStorage::Service.url_expires_in = 1.hour

# We want to run the virus scan on every ActiveStorage attachment,
# regardless of its type (user-uploaded document, instructeur-uploaded attestation, form template, etc.)
#
# To do this, the best place to work on is the ActiveStorage::Attachment
# objects themselves.
#
# We have to monkey patch ActiveStorage in order to always run an analyzer.
# The way analyzable blob interface work is by running the first accepted analyzer.
# This is not what we want for the virus scan. Using analyzer interface is still beneficial
# as it takes care of downloading the blob.
ActiveStorage::Attached::One.class_eval do
  def virus_scanner
    if attached?
      ActiveStorage::VirusScanner.new(attachment.blob)
    end
  end
end

ActiveSupport.on_load(:active_storage_blob) { include BlobVirusScanner }
