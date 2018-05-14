class DeviseUserMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    DeviseUserMailer.confirmation_instructions(User.first, "faketoken", {})
  end

  def reset_password_instructions
    DeviseUserMailer.reset_password_instructions(User.first, "faketoken", {})
  end
end
