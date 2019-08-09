class Administration < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable, :validatable, :omniauthable, :lockable, :async, omniauth_providers: [:github]

  def self.from_omniauth(params)
    find_by(email: params["info"]["email"])
  end

  def invite_admin(email)
    password = SecureRandom.hex

    user = User.find_by(email: email)

    if user.nil?
      # set confirmed_at otherwise admin confirmation doesnt work
      # we somehow mess up using reset_password logic instead of
      # confirmation_logic
      # FIXME
      user = User.create(
        email: email,
        password: password,
        confirmed_at: Time.zone.now
      )
    end

    if user.errors.empty?
      if user.instructeur.nil?
        Instructeur.create!(email: email, user: user)
      end

      if user.administrateur.nil?
        administrateur = Administrateur.create!(email: email, active: false, user: user)
        AdministrationMailer.new_admin_email(administrateur, self).deliver_later
        user.invite_administrateur!(id)
      end
    end

    user
  end
end
