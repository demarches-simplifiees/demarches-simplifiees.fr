class Cerfa < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :user

  mount_uploader :content, CerfaUploader
  validates :content, :file_size => {:maximum => 3.megabytes}

  def empty?
    content.blank?
  end

  def content_url
    if Features.remote_storage and !content.url.nil?
      (RemoteDownloader.new content.filename).url
    else
      unless content.url.nil?
        (LocalDownloader.new content, 'CERFA').url
      end
    end
  end
end