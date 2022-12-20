describe Users::ProfilController, type: :controller do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  before { sign_in(user) }

  describe 'GET #show' do
    render_views

    before { post :show }

    context 'when the current user is not an instructeur' do
      it { expect(response.body).to include(I18n.t('users.profil.show.transfer_title')) }

      context 'when an existing transfer exists' do
        let(:dossiers) { Array.new(3) { create(:dossier, user: user) } }
        let(:next_owner) { 'loulou@lou.com' }
        let!(:transfer) { DossierTransfer.initiate(next_owner, dossiers) }

        before { post :show }

        it { expect(response.body).to include(I18n.t('users.profil.show.one_waiting_transfer', count: dossiers.count, email: next_owner)) }
      end
    end

    context 'when the current user is an instructeur' do
      let(:user) { create(:instructeur).user }

      it { expect(response.body).not_to include(I18n.t('users.profil.show.transfer_title')) }
    end
  end

  describe 'PATCH #update_email' do
    context 'when email is same as user' do
      it 'fails' do
        patch :update_email, params: { user: { email: user.email } }
        expect(response).to have_http_status(302)
        expect(flash[:alert]).to eq(["Le champ « La nouvelle adresse email » ne peut être identique à l’ancienne. Saisir une autre adresse email"])
      end
    end

    context 'when everything is fine' do
      let(:previous_request) { create(:user) }

      before do
        user.update(requested_merge_into: previous_request)
        patch :update_email, params: { user: { email: 'loulou@lou.com' } }
        user.reload
      end

      it { expect(user.unconfirmed_email).to eq('loulou@lou.com') }
      it { expect(user.requested_merge_into).to be_nil }
      it { expect(response).to redirect_to(profil_path) }
      it { expect(flash.notice).to eq(I18n.t('devise.registrations.update_needs_confirmation')) }
    end

    context 'when the mail is already taken' do
      let(:existing_user) { create(:user) }

      before do
        user.update(unconfirmed_email: 'unconfirmed@mail.com')

        expect(UserMailer).to receive(:ask_for_merge).with(user, existing_user.email).and_return(double(deliver_later: true))

        perform_enqueued_jobs do
          patch :update_email, params: { user: { email: existing_user.email } }
        end
        user.reload
      end

      it 'launches the merge process' do
        expect(user.unconfirmed_email).to be_nil
        expect(response).to redirect_to(profil_path)
        expect(flash.notice).to eq(I18n.t('devise.registrations.update_needs_confirmation'))
      end
    end

    context 'when the mail is incorrect' do
      before do
        patch :update_email, params: { user: { email: 'incorrect' } }
        user.reload
      end

      it { expect(response).to redirect_to(profil_path) }
      it { expect(flash.alert).to eq(["Le champ « Adresse éléctronique » est invalide. Saisir une adresse éléctronique valide, exemple : john.doe@exemple.fr"]) }
    end

    context 'when the user has an instructeur role' do
      let(:instructeur_email) { 'instructeur_email@a.com' }
      let!(:user) { create(:instructeur, email: instructeur_email).user }

      before do
        patch :update_email, params: { user: { email: requested_email } }
        user.reload
      end

      context 'when the requested email is allowed' do
        let(:requested_email) { 'legit@gouv.fr' }

        it { expect(user.unconfirmed_email).to eq('legit@gouv.fr') }
        it { expect(response).to redirect_to(profil_path) }
        it { expect(flash.notice).to eq(I18n.t('devise.registrations.update_needs_confirmation')) }
      end

      context 'when the requested email is not allowed' do
        let(:requested_email) { 'weird@gmail.com' }

        it { expect(response).to redirect_to(profil_path) }
        it { expect(flash.alert).to include('contactez le support') }
      end
    end
  end

  context 'POST #transfer_all_dossiers' do
    let!(:dossiers) { Array.new(3) { create(:dossier, user: user) } }
    let(:next_owner) { 'loulou@lou.com' }
    let(:created_transfer) { DossierTransfer.first }

    subject {
      post :transfer_all_dossiers, params: { next_owner: next_owner }
    }

    before { subject }

    it "transfer all dossiers" do
      expect(created_transfer.email).to eq(next_owner)
      expect(created_transfer.dossiers).to match_array(dossiers)
      expect(flash.notice).to eq("Le transfert de 3 dossiers à #{next_owner} est en cours")
    end

    context "next owner has an empty email" do
      let(:next_owner) { '' }

      it "should not transfer to an empty email" do
        expect { subject }.not_to change { DossierTransfer.count }
        expect(flash.alert).to eq(["L'adresse email est invalide"])
      end
    end
  end

  context 'POST #accept_merge' do
    let!(:requesting_user) { create(:user, requested_merge_into: user) }

    subject { post :accept_merge }

    it 'merges the account' do
      expect_any_instance_of(User).to receive(:merge)

      subject
      requesting_user.reload

      expect(requesting_user.requested_merge_into).to be_nil
      expect(flash.notice).to include('Vous avez absorbé')
      expect(response).to redirect_to(profil_path)
    end
  end

  context 'POST #refuse_merge' do
    let!(:requesting_user) { create(:user, requested_merge_into: user) }

    subject { post :refuse_merge }

    it 'merges the account' do
      expect_any_instance_of(User).not_to receive(:merge)

      subject
      requesting_user.reload

      expect(requesting_user.requested_merge_into).to be_nil
      expect(flash.notice).to include('La fusion a été refusé')
      expect(response).to redirect_to(profil_path)
    end
  end

  context 'DELETE #destroy_fci' do
    let!(:fci) { create(:france_connect_information, user: user) }

    subject { delete :destroy_fci, params: { fci_id: fci.id } }

    it do
      expect(FranceConnectInformation.where(user: user).count).to eq(1)
      subject
      expect(FranceConnectInformation.where(user: user).count).to eq(0)
      expect(response).to redirect_to(profil_path)
    end
  end
end
