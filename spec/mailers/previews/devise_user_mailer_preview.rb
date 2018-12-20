class DeviseUserMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    DeviseUserMailer.confirmation_instructions(user, "faketoken", {})
  end

  def reset_password_instructions
    DeviseUserMailer.reset_password_instructions(user, "faketoken", {})
  end

  private

  def user
    User.new(id: 10, email: "usager@example.com")
  end
end
