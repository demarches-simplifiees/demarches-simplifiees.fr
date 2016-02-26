class Cerfa < ActiveRecord::Base
  belongs_to :dossier

  mount_uploader :content, CerfaUploader
  validates :content, :file_size => {:maximum => 3.megabytes}

  def empty?
    content.blank?
  end

  def content_url
    unless content.url.nil?
      (Downloader.new content, 'CERFA').url
    end
  end
end