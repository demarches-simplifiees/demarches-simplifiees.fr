require 'spec_helper'

describe NewGestionnaire::DossiersController, type: :controller do
  let(:gestionnaire) { create(:gestionnaire) }
  let(:procedure) { create(:procedure, gestionnaires: [gestionnaire]) }
  let(:dossier) { create(:dossier, procedure: procedure) }

  before { sign_in(gestionnaire) }

  describe 'attestation' do
    context 'when a dossier has an attestation' do
      let(:fake_pdf) { double(read: 'pdf content') }
      let!(:dossier) { create(:dossier, attestation: Attestation.new, procedure: procedure) }

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

  describe 'follow' do
    before { patch :follow, params: { procedure_id: procedure.id, dossier_id: dossier.id } }

    it { expect(gestionnaire.followed_dossiers).to match([dossier]) }
    it { expect(response).to redirect_to(procedures_url) }
  end

  describe 'unfollow' do
    before do
      gestionnaire.followed_dossiers << dossier
      patch :unfollow, params: { procedure_id: procedure.id, dossier_id: dossier.id }
      gestionnaire.reload
    end

    it { expect(gestionnaire.followed_dossiers).to match([]) }
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
