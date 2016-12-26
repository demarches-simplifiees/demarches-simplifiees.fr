class Cerfa < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :user

  mount_uploader :content, CerfaUploader
  validates :content, :file_size => {:maximum => 20.megabytes}

  after_save :internal_notification

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

  private

  def internal_notification
    unless dossier.state == 'draft'
      NotificationService.new('cerfa', self.dossier.id).notify
    end
  end
end