module UserInvitationConcern
  extend ActiveSupport::Concern

  private

  def maybe_typos_and_emails
    emails = params['emails'].presence || [].to_json
    JSON.parse(emails).map { EmailSanitizableConcern::EmailSanitizer.sanitize(_1) }
      .map { |email| [email, EmailChecker.check(email:)[:suggestions]&.first] }
      .partition { _1[1].present? }
  end
end
