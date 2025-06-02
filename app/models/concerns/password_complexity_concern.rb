# frozen_string_literal: true

module PasswordComplexityConcern
  extend ActiveSupport::Concern

  # Allows adding a condition to the password complexity validation.
  # Default is yes. Can be overridden in included classes.
  def validate_password_complexity?
    true
  end

  def min_password_complexity
    PASSWORD_COMPLEXITY_FOR_ADMIN
  end

  included do
    # Add a validator for password complexity.
    #
    # The validator triggers as soon as the password is long enough (to avoid presenting
    # two errors when the password is too short, one about length and one about complexity).
    validates :password, password_complexity: true, if: -> { password_has_minimum_length? && validate_password_complexity? }
  end

  private

  def password_has_minimum_length?
    self.class.password_length.include?(password.try(:size))
  end
end
