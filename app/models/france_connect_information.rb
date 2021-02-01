# == Schema Information
#
# Table name: france_connect_informations
#
#  id                            :integer          not null, primary key
#  birthdate                     :date
#  birthplace                    :string
#  email_france_connect          :string
#  family_name                   :string
#  gender                        :string
#  given_name                    :string
#  created_at                    :datetime
#  updated_at                    :datetime
#  france_connect_particulier_id :string
#  user_id                       :integer
#
class FranceConnectInformation < ApplicationRecord
  belongs_to :user, optional: true

  validates :france_connect_particulier_id, presence: true, allow_blank: false, allow_nil: false

  def associate_user!
    user = User.find_by(email: email_france_connect.downcase)

    if user.nil?
      user = User.create!(
        email: email_france_connect.downcase,
        password: Devise.friendly_token[0, 20],
        confirmed_at: Time.zone.now
      )
    end

    update_attribute('user_id', user.id)
  end
end
