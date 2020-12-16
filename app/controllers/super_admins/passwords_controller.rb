class SuperAdmins::PasswordsController < Devise::PasswordsController
  def update
    super
    self.resource.disable_otp!
  end

  def test_strength
    @score, @words, @length = ZxcvbnService.new(password_params[:password]).complexity
    @min_length = PASSWORD_MIN_LENGTH
    @min_complexity = PASSWORD_COMPLEXITY_FOR_ADMIN
    render 'shared/password/test_strength'
  end

  private

  def password_params
    params.require(:super_admin).permit(:password)
  end
end
