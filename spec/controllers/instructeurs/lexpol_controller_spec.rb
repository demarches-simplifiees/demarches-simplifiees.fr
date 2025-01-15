require 'rails_helper'

RSpec.describe Instructeurs::LexpolController, type: :controller do
  render_views

  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }
  let(:dossier) { create(:dossier, procedure: procedure) }
  let(:champ) { create(:champ, dossier: dossier) }

  before do
    sign_in instructeur.user
    allow(Dossier).to receive(:find).and_return(dossier)
    allow(dossier.champs).to receive(:find).and_return(champ)
  end

  describe 'POST #upsert' do
    context 'when dossier creation is successful' do
      before do
        allow(champ).to receive(:value).and_return(nil)
        allow_any_instance_of(LexpolService).to receive(:upsert_dossier).and_return('NOR-12345')

        post :upsert, params: {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          champ_id: champ.id
        }
      end

      it 'redirects to annotations page with success message for creation' do
        expect(response).to redirect_to(annotations_privees_instructeur_dossier_path(procedure, dossier))
        expect(flash[:notice]).to eq('Dossier Lexpol créé avec succès. NOR : NOR-12345')
      end
    end

    context 'when dossier update is successful' do
      before do
        allow(champ).to receive(:value).and_return('NOR-12345')
        allow_any_instance_of(LexpolService).to receive(:upsert_dossier).and_return('NOR-12345')

        post :upsert, params: {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          champ_id: champ.id
        }
      end

      it 'redirects to annotations page with success message for update' do
        expect(response).to redirect_to(annotations_privees_instructeur_dossier_path(procedure, dossier))
        expect(flash[:notice]).to eq('Dossier Lexpol mis à jour avec succès. NOR : NOR-12345')
      end
    end

    context 'when dossier creation fails' do
      before do
        allow(champ).to receive(:value).and_return(nil) # Simule un NOR vide
        allow_any_instance_of(LexpolService).to receive(:upsert_dossier).and_return(nil)

        post :upsert, params: {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          champ_id: champ.id
        }
      end

      it 'redirects to annotations page with error message for creation' do
        expect(response).to redirect_to(annotations_privees_instructeur_dossier_path(procedure, dossier))
        expect(flash[:alert]).to eq('Impossible de créer le dossier Lexpol.')
      end
    end

    context 'when dossier update fails' do
      before do
        allow(champ).to receive(:value).and_return('NOR-12345') # Simule un NOR existant
        allow_any_instance_of(LexpolService).to receive(:upsert_dossier).and_return(nil)

        post :upsert, params: {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          champ_id: champ.id
        }
      end

      it 'redirects to annotations page with error message for update' do
        expect(response).to redirect_to(annotations_privees_instructeur_dossier_path(procedure, dossier))
        expect(flash[:alert]).to eq('Impossible de mettre à jour le dossier Lexpol.')
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
