class CommentaireFileUploader < BaseUploader
  def root
    File.join(Rails.root, 'public')
  end

  if Features.remote_storage
    storage :fog
  else
    storage :file
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
end
