# frozen_string_literal: true

module UserFindByConcern
  extend ActiveSupport::Concern

  included do
    def self.by_email(email)
      find_by(users: { email: email })
    end

    def self.find_all_by_identifier(ids: [], emails: [])
      find_all_by_identifier_with_emails(ids:, emails:).first
    end

    def self.find_all_by_identifier_with_emails(ids: [], emails: [])
      valid_emails, invalid_emails = emails.partition { StrictEmailValidator::REGEXP.match?(_1) }

      [
        where(id: ids).or(where(users: { email: valid_emails })).distinct(:id),
        valid_emails,
        invalid_emails,
      ]
    end
  end
end
