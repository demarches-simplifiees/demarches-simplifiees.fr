RSpec.describe AdministrationMailer, type: :mailer do
  describe '#new_admin_email' do
    let(:admin) { create(:administrateur) }
    let(:administration) { create(:super_admin) }

    subject { described_class.new_admin_email(admin, administration) }

    it { expect(subject.subject).not_to be_empty }
  end

  describe '#invite_admin' do
    let(:admin_user) { create(:user, last_sign_in_at: last_sign_in_at) }
    let(:token) { "some_token" }
    let(:administration_id) { BizDev::PIPEDRIVE_ID }
    let(:last_sign_in_at) { nil }

    subject { described_class.invite_admin(admin_user, token, administration_id) }

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

  describe '#dubious_procedures' do
    let(:procedures_and_type_de_champs) { [] }

    subject { described_class.dubious_procedures(procedures_and_type_de_champs) }

    it { expect(subject.subject).not_to be_empty }
  end
end
