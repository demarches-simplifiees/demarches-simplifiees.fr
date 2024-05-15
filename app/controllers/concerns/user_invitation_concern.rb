module UserInvitationConcern
  extend ActiveSupport::Concern

  private

  def maybe_typos_and_emails
    (params['emails'].presence || [])
      .map { EmailSanitizableConcern::EmailSanitizer.sanitize(_1) }
      .map { |email| [email, EmailChecker.check(email:)[:suggestions]&.first] }
      .partition { _1[1].present? }
  end
end
