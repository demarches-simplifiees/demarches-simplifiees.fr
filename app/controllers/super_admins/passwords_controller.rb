class Administrations::PasswordsController < Devise::PasswordsController
  def update
    super
    self.resource.disable_otp!
  end
end
