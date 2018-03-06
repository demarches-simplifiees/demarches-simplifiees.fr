class Cerfa < ApplicationRecord
  belongs_to :dossier, touch: true
  belongs_to :user

  mount_uploader :content, CerfaUploader
  validates :content, :file_size => { :maximum => 20.megabytes }

  def empty?
    content.blank?
  end

  def content_url
    if content.url.present?
      if Features.remote_storage
        (RemoteDownloader.new content.filename).url
      else
        (LocalDownloader.new content.path, 'CERFA').url
      end
    end
  end
end
