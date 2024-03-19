RSpec.describe AdministrationMailer, type: :mailer do
  describe '#invite_admin' do
    let(:admin_user) { create(:user, last_sign_in_at: last_sign_in_at) }
    let(:token) { "some_token" }
    let(:last_sign_in_at) { nil }

    subject { described_class.invite_admin(admin_user, token) }

    it { expect(subject.subject).not_to be_empty }

    describe "when the user has not been activated" do
      it { expect(subject.body).to include(admin_activate_path(token: token)) }
      it { expect(subject.body).not_to include(edit_user_password_url(admin_user, reset_password_token: token)) }
    end

    describe "when the user is already active" do
      let(:last_sign_in_at) { Time.zone.now }
      it { expect(subject.body).not_to include(admin_activate_path(token: token)) }
      it { expect(subject.body).to include(edit_user_password_url(admin_user, reset_password_token: token)) }
    end
  end

  describe '#refuse_admin' do
    let(:mail) { "l33t-4dm1n@h4x0r.com" }

    subject { described_class.refuse_admin(mail) }

    it { expect(subject.subject).not_to be_empty }
  end
end
