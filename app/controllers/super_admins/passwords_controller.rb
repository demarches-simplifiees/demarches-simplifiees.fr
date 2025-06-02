# frozen_string_literal: true

class SuperAdmins::PasswordsController < Devise::PasswordsController
  include DevisePopulatedResource

  def update
    super
    self.resource.disable_otp!
  end
end
