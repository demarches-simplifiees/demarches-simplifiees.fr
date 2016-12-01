class Profile < ActiveRecord::Base
  belongs_to :user

  mount_uploader :picture, ProfilePictureUploader
  validates :picture, file_size: { maximum: 1.megabyte }

  def gender
    self[:gender] || user.france_connect_information.try(&:gender)
  end

  def given_name
    self[:given_name] || user.france_connect_information.try(&:given_name)
  end

  def family_name
    self[:family_name] || user.france_connect_information.try(&:family_name)
  end

  def birthdate
    self[:birthdate] || user.france_connect_information.try(&:birthdate)
  end
end
