class AttestationTemplateSignatureUploader < BaseUploader
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

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    ['jpg', 'jpeg', 'png']
  end

  def filename
    if file.present?
      "attestation-template-signature-#{secure_token}.#{file.extension.downcase}"
    end
  end

  private

  def secure_token
    model.signature_secure_token ||= SecureRandom.uuid
  end
end
