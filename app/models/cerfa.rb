class Cerfa < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :user

  mount_uploader :content, CerfaUploader
  validates :content, :file_size => {:maximum => 6.megabytes}

  def empty?
    content.blank?
  end

  def content_url
    unless content.url.nil?
      if Features.remote_storage
        (RemoteDownloader.new content.filename).url
      else
        (LocalDownloader.new content.path, 'CERFA').url
      end
    end
  end
end