class CommentaireFileUploader < BaseUploader
  def root
    Rails.root.join("public")
  end

  if Flipflop.remote_storage?
    storage :fog
  else
    storage :file
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_white_list
    ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'odp', 'jpg', 'jpeg', 'png', 'zip', 'txt']
  end

  def accept_extension_list
    extension_white_list.map{ |e| ".#{e}" }.join(",")
  end
end
