# frozen_string_literal: true

describe DossierPolicy do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
  let(:dossier) { create(:dossier, procedure: procedure, user: dossier_owner) }
  let(:dossier_owner) { create(:user) }

  let(:signed_in_user) { create(:user) }
  let(:account) { { user: signed_in_user } }

  subject { Pundit.policy_scope(account, Dossier) }

  shared_examples_for 'they can access dossier' do
    it { expect(subject.find_by(id: dossier.id)).to eq(dossier) }
  end

  shared_examples_for 'they can’t access dossier' do
    it { expect(subject.find_by(id: dossier.id)).to eq(nil) }
  end

  context 'when an user only has user rights' do
    context 'as the dossier owner' do
      let(:signed_in_user) { dossier_owner }

      it_behaves_like 'they can access dossier'
    end

    context 'as a person invited on the dossier' do
      let(:invite) { create(:invite, :with_user, dossier: dossier) }
      let(:signed_in_user) { invite.user }

      it_behaves_like 'they can access dossier'
    end

    context 'as another user' do
      let(:signed_in_user) { create(:user) }

      it_behaves_like 'they can’t access dossier'
    end
  end

  context 'when the user also has instruction rights' do
    let(:instructeur) { create(:instructeur, user: signed_in_user) }
    let(:account) { { user: signed_in_user, instructeur: instructeur } }

    context 'as the dossier instructeur and owner' do
      let(:signed_in_user) { dossier_owner }
      before { instructeur.assign_to_procedure(dossier.procedure) }

      it_behaves_like 'they can access dossier'
    end

    context 'as the dossier instructeur (but not owner)' do
      let(:signed_in_user) { create(:user) }
      before { instructeur.assign_to_procedure(dossier.procedure) }

      it_behaves_like 'they can access dossier'
    end

    context 'as an instructeur not assigned to the procedure' do
      let(:signed_in_user) { create(:user) }

      it_behaves_like 'they can’t access dossier'
    end
  end
end
