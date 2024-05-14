# frozen_string_literal: true

class APITokenMailerPreview < ActionMailer::Preview
  def expiration
    APITokenMailer.expiration(api_token)
  end

  private

  def api_token
    APIToken.new(
      administrateur: administrateur,
      expires_at: 1.week.from_now,
      name: 'My API token'
    )
  end

  def administrateur
    Administrateur.new(user:)
  end

  def user
    User.new(email: 'admin@a.com')
  end
end
