require 'spec_helper'

describe ChampPolicy do
  let(:user) { create(:user) }
  let(:dossier) { create(:dossier, user: user) }
  let!(:champ) { create(:champ_text, dossier: dossier) }

  let(:pundit_user) { user }
  subject { Pundit.policy_scope(pundit_user, Champ) }

  context 'when the user has only user rights' do
    context 'cannot access champs for other dossiers' do
      let(:pundit_user) { create(:user) }

      it { expect(subject.find_by(id: champ.id)).to eq(nil) }
    end

    context 'can access champs for its own dossiers' do
      it {
        expect(subject.find(champ.id)).to eq(champ)
      }
    end
  end

  context 'when the user has only gestionnaire rights' do
    context 'can access champs for dossiers it follows' do
      let(:dossier) { create(:dossier, :followed) }
      let(:pundit_user) { dossier.followers_gestionnaires.first }

      it { expect(subject.find(champ.id)).to eq(champ) }
    end
  end

  context 'when the user has user and gestionnaire rights' do
    let(:pundit_user) { dossier.followers_gestionnaires.first }
    let(:dossier) { create(:dossier, :followed) }

    let(:user) { create(:user, email: pundit_user.email) }
    let(:dossier2) { create(:dossier, user: user) }
    let!(:champ_2) { create(:champ_text, dossier: dossier2) }

    context 'can access champs for dossiers it follows' do
      it do
        expect(pundit_user.user).to eq(user)
        expect(subject.find(champ.id)).to eq(champ)
      end
    end

    context 'can access champs for its own dossiers' do
      it do
        expect(pundit_user.user).to eq(user)
        expect(subject.find(champ_2.id)).to eq(champ_2)
      end
    end
  end
end
