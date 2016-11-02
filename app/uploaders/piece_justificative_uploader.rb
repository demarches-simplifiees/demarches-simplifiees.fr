# encoding: utf-8

class PieceJustificativeUploader < BaseUploader
  before :cache, :set_original_filename

  # Choose what kind of storage to use for this uploader:
  if Features.remote_storage
    storage :fog
  else
    storage :file
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    unless Features.remote_storage
      "./uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(pdf doc docx xls xlsx ppt pptx odt ods odp jpg jpeg png)
  end

  def filename
    if original_filename.present? || model.content_secure_token
      if Features.remote_storage
        filename = "#{model.class.to_s.underscore}-#{secure_token}.#{file.extension.downcase}"
      else original_filename
        filename = "#{model.class.to_s.underscore}.#{file.extension.downcase}"
      end
    end
    filename
  end

  def original_filename
    model.original_filename
  end

  private

  def secure_token
    model.content_secure_token ||= generate_secure_token
  end

  def generate_secure_token
    SecureRandom.uuid
  end

  def set_original_filename(file)
    model.original_filename ||= file.original_filename if file.respond_to?(:original_filename)
  end
end
