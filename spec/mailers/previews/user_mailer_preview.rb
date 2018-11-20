class UserMailerPreview < ActionMailer::Preview
  def new_account_warning
    UserMailer.new_account_warning(User.first)
  end
end
