class Administration < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable, :validatable, :omniauthable, omniauth_providers: [:github]

  def self.from_omniauth(params)
    find_by(email: params["info"]["email"])
  end
end
