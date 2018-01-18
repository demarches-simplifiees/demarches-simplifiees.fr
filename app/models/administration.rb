class Administration < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable, :validatable, :omniauthable, omniauth_providers: [:github]

  def self.from_omniauth(params)
    find_by(email: params["info"]["email"])
  end

  def invite_admin(email)
    administrateur = Administrateur.new({
      email: email,
      active: false
    })
    administrateur.password = administrateur.password_confirmation = SecureRandom.hex

    if administrateur.save
      AdministrationMailer.new_admin_email(administrateur, self).deliver_now!
      administrateur.invite!
    end

    administrateur
  end
end
