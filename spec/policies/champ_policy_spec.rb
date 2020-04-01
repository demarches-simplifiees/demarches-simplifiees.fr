describe ChampPolicy do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
  let(:dossier) { create(:dossier, procedure: procedure, user: dossier_owner) }
  let(:dossier_owner) { create(:user) }

  let(:signed_in_user) { create(:user) }
  let(:account) { { user: signed_in_user } }

  subject { Pundit.policy_scope(account, Champ) }

  let(:champ) { dossier.champs.first }
  let(:champ_private) { dossier.champs_private.first }

  shared_examples_for 'they can access a public champ' do
    it { expect(subject.find_by(id: champ.id)).to eq(champ) }
  end

  shared_examples_for 'they can’t access a public champ' do
    it { expect(subject.find_by(id: champ.id)).to eq(nil) }
  end

  shared_examples_for 'they can access a private champ' do
    it { expect(subject.find_by(id: champ_private.id)).to eq(champ_private) }
  end

  shared_examples_for 'they can’t access a private champ' do
    it { expect(subject.find_by(id: champ_private.id)).to eq(nil) }
  end

  context 'when an user only has user rights' do
    context 'as the dossier owner' do
      let(:signed_in_user) { dossier_owner }

      it_behaves_like 'they can access a public champ'
      it_behaves_like 'they can’t access a private champ'
    end

    context 'as a person invited on the dossier' do
      let(:invite) { create(:invite, :with_user, dossier: dossier) }
      let(:signed_in_user) { invite.user }

      it_behaves_like 'they can access a public champ'
      it_behaves_like 'they can’t access a private champ'
    end

    context 'as another user' do
      let(:signed_in_user) { create(:user) }

      it_behaves_like 'they can’t access a public champ'
      it_behaves_like 'they can’t access a private champ'
    end
  end

  context 'when the user also has instruction rights' do
    let(:instructeur) { create(:instructeur, email: signed_in_user.email, password: signed_in_user.password) }
    let(:account) { { user: signed_in_user, instructeur: instructeur } }

    context 'as the dossier instructeur and owner' do
      let(:signed_in_user) { dossier_owner }
      before { instructeur.assign_to_procedure(dossier.procedure) }

      it_behaves_like 'they can access a public champ'
      it_behaves_like 'they can access a private champ'
    end

    context 'as the dossier instructeur (but not owner)' do
      let(:signed_in_user) { create(:user) }
      before { instructeur.assign_to_procedure(dossier.procedure) }

      it_behaves_like 'they can’t access a public champ'
      it_behaves_like 'they can access a private champ'
    end

    context 'as an instructeur not assigned to the procedure' do
      let(:signed_in_user) { create(:user) }

      it_behaves_like 'they can’t access a public champ'
      it_behaves_like 'they can’t access a private champ'
    end
  end
end
