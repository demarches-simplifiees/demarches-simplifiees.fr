require 'rails_helper'

RSpec.describe Champs::LexpolController, type: :controller do
  render_views

  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :lexpol }], instructeurs: [instructeur]) }
  let(:tdc) { procedure.active_revision.types_de_champ.first }
  let(:dossier) { create(:dossier, procedure:) }

  let(:value) { nil }
  let(:champ) { dossier.champ_for_update(tdc, nil, updated_by: instructeur).tap { |c| c.value = value }.tap(&:save!) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('LEXPOL_EMAIL').and_return('fake_email@example.com')
    allow(ENV).to receive(:fetch).with('LEXPOL_PASSWORD').and_return('fake_password')
    allow(ENV).to receive(:fetch).with('LEXPOL_AGENT_EMAIL').and_return('fake_agent_email@example.com')
    sign_in instructeur.user
  end

  describe 'POST #upsert' do
    context 'when dossier creation is successful' do
      before do
        allow_any_instance_of(LexpolService).to receive(:upsert_dossier).and_return('NOR-12345')

        post :upsert, params: {
          dossier_id: dossier.id,
          stable_id: champ.stable_id
        }
      end

      it 'redirects to annotations page with success message for creation' do
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Dossier Lexpol créé avec succès')
      end
    end

    context 'when dossier update is successful' do
      let(:value) { 'NOR-12345' }
      before do
        allow_any_instance_of(LexpolService).to receive(:upsert_dossier).and_return(value)

        post :upsert, params: {
          dossier_id: dossier.id,
          stable_id: champ.stable_id
        }
      end

      it 'redirects to annotations page with success message for update' do
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Dossier Lexpol mis à jour avec succès')
      end
    end

    context 'when dossier creation fails' do
      before do
        allow_any_instance_of(LexpolService).to receive(:upsert_dossier).and_raise(StandardError.new("test"))

        post :upsert, params: {
          dossier_id: dossier.id,
          stable_id: champ.stable_id
        }
      end

      it 'redirects to annotations page with error message for creation' do
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Impossible de créer le dossier Lexpol. test')
      end
    end

    context 'when dossier update fails' do
      let(:value) { 'NOR-12345' }
      before do
        champ
        allow_any_instance_of(LexpolService).to receive(:upsert_dossier).and_raise(StandardError.new("test"))

        post :upsert, params: {
          dossier_id: dossier.id,
          stable_id: champ.stable_id
        }
      end

      it 'redirects to annotations page with error message for update' do
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Impossible de mettre à jour le dossier Lexpol. test')
      end
    end

    context 'when required parameters are missing' do
      it 'raises an error for missing dossier_id' do
        expect {
          post :upsert, params: { champ_id: champ.id }
        }.to raise_error(ActionController::UrlGenerationError)
      end

      it 'raises an error for missing champ_id' do
        expect {
          post :upsert, params: { dossier_id: dossier.id }
        }.to raise_error(ActionController::UrlGenerationError)
      end
    end
  end
end
