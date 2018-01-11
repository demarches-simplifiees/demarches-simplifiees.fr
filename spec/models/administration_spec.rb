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
  end
end
