# frozen_string_literal: true

module EmailVerifiableConcern
  extend ActiveSupport::Concern

  class_methods do
    def with_verify_email_token(token)
      user = GlobalID::Locator.locate_signed(token, for: 'verify_email')
      user if user.is_a?(self)
    end
  end

  def verify_email_token
    # use globalid to serialize the user
    self.to_sgid(for: 'verify_email', expires_in: nil).to_s
  end
end
