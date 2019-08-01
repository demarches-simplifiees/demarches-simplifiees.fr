require 'spec_helper'

describe ChampPolicy do
  let(:user) { create(:user) }
  let(:dossier) { create(:dossier, user: user) }
  let!(:champ) { create(:champ_text, dossier: dossier) }

  let(:account) { { user: user } }

  subject { Pundit.policy_scope(account, Champ) }

  context 'when the user has only user rights' do
    context 'cannot access champs for other dossiers' do
      let(:account) { { user: create(:user) } }

      it { expect(subject.find_by(id: champ.id)).to eq(nil) }
    end

    context 'can access champs for its own dossiers' do
      it {
        expect(subject.find(champ.id)).to eq(champ)
      }
    end
  end
end
