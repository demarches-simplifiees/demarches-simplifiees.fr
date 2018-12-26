class UserMailerPreview < ActionMailer::Preview
  def new_account_warning
    UserMailer.new_account_warning(user)
  end

  private

  def user
    User.new(id: 10, email: 'test@exemple.fr')
  end
end
