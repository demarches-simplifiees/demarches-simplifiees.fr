class User < ActiveRecord::Base
  enum loged_in_with_france_connect: {particulier: 'particulier',
                                      entreprise: 'entreprise'}

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :dossiers, dependent: :destroy

  def self.find_for_france_connect_particulier user_info

    User.find_by(france_connect_particulier_id: user_info[:france_connect_particulier_id])
  end

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
end
