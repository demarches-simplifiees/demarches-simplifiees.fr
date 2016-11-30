class User < ActiveRecord::Base
  enum loged_in_with_france_connect: {particulier: 'particulier',
                                      entreprise: 'entreprise'}

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :dossiers, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :piece_justificative, dependent: :destroy
  has_many :cerfa, dependent: :destroy
  has_one :france_connect_information, dependent: :destroy

  delegate :email_france_connect, :gender, :birthplace, :france_connect_particulier_id, to: :france_connect_information

  accepts_nested_attributes_for :france_connect_information
  after_update :sync_credentials, if: -> { Features.unified_login }

  mount_uploader :picture, ProfilePictureUploader
  validates :picture, file_size: { maximum: 1.megabyte }

  def self.find_for_france_connect email, siret
    user = User.find_by_email(email)
    if user.nil?
      return User.create(email: email, password: Devise.friendly_token[0, 20], siret: siret)
    else
      user.update_attributes(siret: siret)
      user
    end
  end

  def loged_in_with_france_connect?
    !loged_in_with_france_connect.nil?
  end

  def invite? dossier_id
    invites.pluck(:dossier_id).include?(dossier_id.to_i)
  end

  def gender
    self[:gender] || france_connect_information.try(&:gender)
  end

  def given_name
    self[:given_name] || france_connect_information.try(&:given_name)
  end

  def family_name
    self[:family_name] || france_connect_information.try(&:family_name)
  end

  def birthdate
    self[:birthdate] || france_connect_information.try(&:birthdate)
  end

  def picture_url
    if Features.remote_storage
      File.join(STORAGE_URL, picture.path)
    else
      picture.url
    end
  end

  private

  def sync_credentials
    if email_changed? || encrypted_password_changed?
      gestionnaire = Gestionnaire.find_by(email: email_was)
      if gestionnaire
        return gestionnaire.update_columns(
          email: email,
          encrypted_password: encrypted_password)
      end
    end
    true
  end
end
