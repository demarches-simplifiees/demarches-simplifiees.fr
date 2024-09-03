# frozen_string_literal: true

class FranceConnectInformation < ApplicationRecord
  MERGE_VALIDITY = 15.minutes

  belongs_to :user, optional: true

  validates :france_connect_particulier_id, presence: true, allow_blank: false, allow_nil: false

  def associate_user!(email)
    begin
      user = User.create!(
        email: email.downcase,
        password: Devise.friendly_token[0, 20],
        confirmed_at: Time.zone.now
      )
      user.after_confirmation
    rescue ActiveRecord::RecordNotUnique
      # ignore this exception because we check before is user is nil.
      # exception can be raised in race conditions, when FranceConnect calls callback 2 times.
      # At the 2nd call, user is nil but exception is raised at the creation of the user
      # because the first call has already created a user
    end

    update_attribute('user_id', user.id)
    touch # needed to update updated_at column
  end

  def create_merge_token!
    merge_token = SecureRandom.uuid
    update(merge_token:, merge_token_created_at: Time.zone.now)

    merge_token
  end

  def create_email_merge_token!
    email_merge_token = SecureRandom.uuid
    update(email_merge_token:, email_merge_token_created_at: Time.zone.now)

    email_merge_token
  end

  def valid_for_merge?
    (MERGE_VALIDITY.ago < merge_token_created_at) && user_id.nil?
  end

  def valid_for_email_merge?
    (MERGE_VALIDITY.ago < email_merge_token_created_at) && user_id.nil?
  end

  def delete_merge_token!
    update(merge_token: nil, merge_token_created_at: nil)
  end

  def delete_email_merge_token!
    update(email_merge_token: nil, email_merge_token_created_at: nil)
  end

  def full_name
    [given_name, family_name].compact.join(" ")
  end
end
