class PieceJustificativeUploader < BaseUploader
  before :cache, :set_original_filename

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
      "./uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'odp', 'jpg', 'jpeg', 'png']
  end

  def filename
    if original_filename.present? || model.content_secure_token
      if Flipflop.remote_storage?
        filename = "#{model.class.to_s.underscore}-#{secure_token}.#{file.extension&.downcase}"
      else
        filename = "#{model.class.to_s.underscore}.#{file.extension&.downcase}"
      end
    end
    filename
  end

  private

  def secure_token
    model.content_secure_token ||= generate_secure_token
  end

  def generate_secure_token
    SecureRandom.uuid
  end

  def set_original_filename(file)
    if file.respond_to?(:original_filename)
      model.original_filename ||= file.original_filename
    end
  end
end
