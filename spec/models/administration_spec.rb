describe Administration, type: :model do
  describe '#invite_admin' do
    let(:administration) { create :administration }
    let(:valid_email) { 'paul@tps.fr' }

    subject { administration.invite_admin(valid_email) }

    it {
      user = subject
      expect(user.errors).to be_empty
      expect(user).to be_persisted
    }

    it { expect(administration.invite_admin(nil).errors).not_to be_empty }
    it { expect(administration.invite_admin('toto').errors).not_to be_empty }

    it 'creates a corresponding user account for the email' do
      subject
      user = User.find_by(email: valid_email)
      expect(user).to be_present
    end

    it 'creates a corresponding instructeur account for the email' do
      subject
      instructeur = Instructeur.by_email(valid_email)
      expect(instructeur).to be_present
    end

    context 'when there already is a user account with the same email' do
      before { create(:user, email: valid_email) }
      it 'still creates an admin account' do
        expect(subject.errors).to be_empty
        expect(subject).to be_persisted
      end
    end
  end

  describe 'enable_otp!' do
    let(:administration) { create(:administration, otp_required_for_login: false) }
    let(:subject) { administration.enable_otp! }

    it 'updates otp_required_for_login' do
      expect { subject }.to change { administration.otp_required_for_login? }.from(false).to(true)
    end

    it 'updates otp_secret' do
      expect { subject }.to change { administration.otp_secret }
    end
  end

  describe 'disable_otp!' do
    let(:administration) { create(:administration, otp_required_for_login: true) }
    let(:subject) { administration.disable_otp! }

    it 'updates otp_required_for_login' do
      expect { subject }.to change { administration.otp_required_for_login? }.from(true).to(false)
    end

    it 'nullifies otp_secret' do
      administration.enable_otp!
      expect { subject }.to change { administration.reload.otp_secret }.to(nil)
    end
  end
end
