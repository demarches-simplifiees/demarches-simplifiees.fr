require 'spec_helper'

describe NewUser::DossiersController, type: :controller do
  let(:user) { create(:user) }

  describe 'before_action: ensure_ownership!' do
    it 'is present' do
      before_actions = NewUser::DossiersController
        ._process_action_callbacks
        .find_all{ |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:ensure_ownership!)
    end
  end

  describe 'ensure_ownership!' do
    let(:user) { create(:user) }

    before do
      @controller.params = @controller.params.merge(dossier_id: asked_dossier.id)
      expect(@controller).to receive(:current_user).and_return(user)
      allow(@controller).to receive(:redirect_to)

      @controller.send(:ensure_ownership!)
    end

    context 'when a user asks for its dossier' do
      let(:asked_dossier) { create(:dossier, user: user) }

      it 'does not redirects nor flash' do
        expect(@controller).not_to have_received(:redirect_to)
        expect(flash.alert).to eq(nil)
      end
    end

    context 'when a user asks for another dossier' do
      let(:asked_dossier) { create(:dossier) }

      it 'redirects and flash' do
        expect(@controller).to have_received(:redirect_to).with(root_path)
        expect(flash.alert).to eq("Vous n'avez pas accès à ce dossier")
      end
    end
  end

  describe 'attestation' do
    before { sign_in(user) }

    context 'when a dossier has an attestation' do
      let(:fake_pdf) { double(read: 'pdf content') }
      let!(:dossier) { create(:dossier, attestation: Attestation.new, user: user) }

      it 'returns the attestation pdf' do
        allow_any_instance_of(Attestation).to receive(:pdf).and_return(fake_pdf)

        expect(controller).to receive(:send_data)
          .with('pdf content', filename: 'attestation.pdf', type: 'application/pdf') do
            controller.head :ok
          end

        get :attestation, params: { dossier_id: dossier.id }
        expect(response).to have_http_status(:success)
      end
    end
  end
end
