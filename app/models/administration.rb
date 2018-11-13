class Administration < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable, :validatable, :omniauthable, :async, omniauth_providers: [:github]

  def self.from_omniauth(params)
    find_by(email: params["info"]["email"])
  end

  def invite_admin(email)
    password = SecureRandom.hex
    administrateur = Administrateur.new({
      email: email,
      active: false,
      password: password,
      password_confirmation: password
    })

    if administrateur.save
      AdministrationMailer.new_admin_email(administrateur, self).deliver_later
      administrateur.invite!(id)

      User.create({
        email: email,
        password: password,
        confirmed_at: Time.zone.now
      })

      Gestionnaire.create({
        email: email,
        password: password
      })
    end

    administrateur
  end
end
