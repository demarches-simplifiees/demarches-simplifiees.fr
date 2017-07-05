require 'spec_helper'

describe NewGestionnaire::DossiersController, type: :controller do
  let(:gestionnaire) { create(:gestionnaire) }
  before { sign_in(gestionnaire) }

  describe 'attestation' do
    context 'when a dossier has an attestation' do
      let(:fake_pdf) { double(read: 'pdf content') }
      let!(:procedure) { create(:procedure, gestionnaires: [gestionnaire]) }
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
end
