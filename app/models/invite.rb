class Invite < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :user

  validates_presence_of :email
  validates_uniqueness_of :email, :scope => :dossier_id

  validates :email, email_format: true
end
