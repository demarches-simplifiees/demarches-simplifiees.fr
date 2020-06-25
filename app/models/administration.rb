class Administration < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable, :validatable, :omniauthable, :lockable, :async, omniauth_providers: [:github]

  def self.from_omniauth(params)
    find_by(email: params["info"]["email"])
  end

  def invite_admin(email)
    user = User.create_or_promote_to_administrateur(email, SecureRandom.hex)

    if user.valid?
      user.invite_administrateur!(id)
    end

    user
  end
end
