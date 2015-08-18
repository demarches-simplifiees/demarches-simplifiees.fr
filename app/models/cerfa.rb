class Cerfa < ActiveRecord::Base
  belongs_to :dossier

  mount_uploader :content, CerfaUploader
end