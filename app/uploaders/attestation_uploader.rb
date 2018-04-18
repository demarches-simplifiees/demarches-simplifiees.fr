class AttestationUploader < BaseUploader
  def root
    Rails.root.join("public")
  end

  # Choose what kind of storage to use for this uploader:
  if Flipflop.remote_storage?
    storage :fog
  else
    storage :file
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if !Flipflop.remote_storage?
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
  end

  def filename
    "attestation-#{secure_token}.pdf"
  end

  private

  def secure_token
    model.content_secure_token ||= SecureRandom.uuid
  end
end
