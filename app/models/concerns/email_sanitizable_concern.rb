# frozen_string_literal: true

module EmailSanitizableConcern
  extend ActiveSupport::Concern

  def sanitize_email(attribute)
    value_to_sanitize = self.send(attribute)
    if value_to_sanitize.present?
      self[attribute] = EmailSanitizer.sanitize(value_to_sanitize)
    end
  end

  def generate_emails_suggestions_message(suggestions)
    return if suggestions.empty?

    typo_list = suggestions.map(&:first).join(', ')
    verification_link = view_context.link_to("vérifier l’orthographe", "#maybe_typos_errors")

    "Attention, nous pensons avoir identifié une faute de frappe dans les invitations : #{typo_list}. Veuillez #{verification_link} des invitations."
  end

  def check_if_typo(emails)
    emails = emails.map { EmailSanitizer.sanitize(_1) }
    @maybe_typos, no_suggestions = emails
      .map { |email| [email, EmailChecker.check(email:)[:suggestions]&.first] }
      .partition { _1[1].present? }

    emails = no_suggestions.map(&:first)
    emails << EmailSanitizer.sanitize(params['final_email']) if params['final_email'].present?
    emails
  end

  class EmailSanitizer
    def self.sanitize(value)
      value.gsub(/[[:space:]]/, ' ').strip.downcase
    end
  end
end
