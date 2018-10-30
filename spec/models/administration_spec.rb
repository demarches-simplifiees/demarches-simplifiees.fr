require 'spec_helper'

describe Administration, type: :model do
  describe '#invite_admin' do
    let(:administration) { create :administration }
    let(:valid_email) { 'paul@tps.fr' }
    subject { administration.invite_admin(valid_email) }

    it {
      expect(subject.errors).to be_empty
      expect(subject).to be_persisted
      expect(administration.invite_admin(valid_email).errors).not_to be_empty
    }
    it { expect(administration.invite_admin(nil).errors).not_to be_empty }
    it { expect(administration.invite_admin('toto').errors).not_to be_empty }

    it 'creates a corresponding user account for the email' do
      subject
      user = User.find_by(email: valid_email)
      expect(user).to be_present
    end

    it 'creates a corresponding gestionnaire account for the email' do
      subject
      gestionnaire = Gestionnaire.find_by(email: valid_email)
      expect(gestionnaire).to be_present
    end

    context 'when there already is a user account with the same email' do
      before { create(:user, email: valid_email) }
      it 'still creates an admin account' do
        expect(subject.errors).to be_empty
        expect(subject).to be_persisted
      end
    end
  end
end
