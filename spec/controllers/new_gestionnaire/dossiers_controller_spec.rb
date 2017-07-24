require 'spec_helper'

describe NewGestionnaire::DossiersController, type: :controller do
  let(:gestionnaire) { create(:gestionnaire) }
  let(:procedure) { create(:procedure, :published, gestionnaires: [gestionnaire]) }
  let(:dossier) { create(:dossier, :replied, procedure: procedure) }

  describe 'attestation' do
    before { sign_in(gestionnaire) }

    context 'when a dossier has an attestation' do
      let(:fake_pdf) { double(read: 'pdf content') }
      let!(:dossier) { create(:dossier, :replied, attestation: Attestation.new, procedure: procedure) }
      let!(:procedure) { create(:procedure, :published, gestionnaires: [gestionnaire]) }
      let!(:dossier) { create(:dossier, :replied, attestation: Attestation.new, procedure: procedure) }

      it 'returns the attestation pdf' do
        allow_any_instance_of(Attestation).to receive(:pdf).and_return(fake_pdf)

        expect(controller).to receive(:send_data)
          .with('pdf content', filename: 'attestation.pdf', type: 'application/pdf') do
            controller.render nothing: true
          end

        get :attestation, params: { procedure_id: procedure.id, dossier_id: dossier.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  context "when gestionnaire is signed in" do
    before { sign_in(gestionnaire) }

    describe 'follow' do
      before do
        expect_any_instance_of(Dossier).to receive(:next_step!).with('gestionnaire', 'follow')
        patch :follow, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      end

      it { expect(gestionnaire.followed_dossiers).to match([dossier]) }
      it { expect(flash.notice).to eq('Dossier suivi') }
      it { expect(response).to redirect_to(procedures_url) }
    end

    describe 'unfollow' do
      before do
        gestionnaire.followed_dossiers << dossier
        patch :unfollow, params: { procedure_id: procedure.id, dossier_id: dossier.id }
        gestionnaire.reload
      end

      it { expect(gestionnaire.followed_dossiers).to match([]) }
      it { expect(flash.notice).to eq("Vous ne suivez plus le dossier nº #{dossier.id}") }
      it { expect(response).to redirect_to(procedures_url) }
    end

    describe 'archive' do
      before do
        patch :archive, params: { procedure_id: procedure.id, dossier_id: dossier.id }
        dossier.reload
      end

      it { expect(dossier.archived).to be true }
      it { expect(response).to redirect_to(procedures_url) }
    end

    describe 'unarchive' do
      before do
        dossier.update_attributes(archived: true)
        patch :unarchive, params: { procedure_id: procedure.id, dossier_id: dossier.id }
        dossier.reload
      end

      it { expect(dossier.archived).to be false }
      it { expect(response).to redirect_to(procedures_url) }
    end
  end

  describe "#show" do
    let(:procedure) { create(:procedure, :published, gestionnaires: [gestionnaire]) }
    let(:dossier){ create(:dossier, :replied, procedure: procedure) }

    subject { get :show, params: { procedure_id: procedure.id, dossier_id: dossier.id } }

    context "when gestionnaire is not logged in" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when gestionnaire is logged in" do
      before { sign_in(gestionnaire) }

      it do
        subject
        expect(response).to have_http_status(:success)
      end

      context "when gestionnaire is not affected on procedure" do
        let(:dossier){ create(:dossier, :replied) }
        it { expect{ subject }.to raise_error(ActiveRecord::RecordNotFound) }
      end
    end
  end

  describe "commentaire" do
    let(:saved_commentaire) { dossier.commentaires.first }

    before do
      sign_in(gestionnaire)

      post :create_commentaire, params: {
        procedure_id: procedure.id,
        dossier_id: dossier.id,
        commentaire: { body: 'body' }
      }
    end

    it { expect(saved_commentaire.body).to eq('body') }
    it { expect(saved_commentaire.email).to eq(gestionnaire.email) }
    it { expect(saved_commentaire.dossier).to eq(dossier) }
    it { expect(response).to redirect_to(messagerie_dossier_path(dossier.procedure, dossier)) }
  end
end
