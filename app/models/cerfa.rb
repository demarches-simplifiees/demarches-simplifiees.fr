class Cerfa < ActiveRecord::Base
  belongs_to :dossier

  mount_uploader :content, CerfaUploader
  validates :content, :file_size => { :maximum => 3.megabytes }

  def empty?
    content.blank?
  end
end