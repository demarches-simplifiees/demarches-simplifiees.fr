class Procedure::InvitationWithTypoComponent < ApplicationComponent
  def initialize(maybe_typo:, url:, title:)
    @maybe_typo = maybe_typo
    @url = url
    @title = title
  end

  def render?
    @maybe_typo.present?
  end

  def maybe_typos
    email_checker = EmailChecker.new

    @maybe_typo.map do |actual_email|
      suggested_email = email_checker.check(email: actual_email)[:email_suggestions].first
      [actual_email, suggested_email]
    end
  end
end
