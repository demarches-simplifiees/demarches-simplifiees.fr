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

  describe 'POST #create_dossier' do
    context 'when dossier creation is successful' do
      before do
        allow(champ).to receive(:lexpol_create_dossier).and_return(true)
        post :create_dossier, params: {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          champ_id: champ.id
        }
      end

      it 'redirects to annotations page with success message' do
        expect(response).to redirect_to(annotations_instructeur_dossier_path(procedure, dossier))
        expect(flash[:notice]).to eq('Dossier Lexpol créé avec succès.')
      end
    end

    context 'when dossier creation fails' do
      before do
        allow(champ).to receive(:lexpol_create_dossier).and_return(false)
        allow(champ).to receive_message_chain(:errors, :full_messages).and_return(['Erreur de création'])
        post :create_dossier, params: {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          champ_id: champ.id
        }
      end

      it 'redirects to annotations page with error message' do
        expect(response).to redirect_to(annotations_instructeur_dossier_path(procedure, dossier))
        expect(flash[:alert]).to eq('Erreur de création')
      end
    end
  end

  describe 'POST #update_dossier' do
    context 'when dossier update is successful' do
      before do
        allow(champ).to receive(:lexpol_update_dossier).and_return(true)
        post :update_dossier, params: {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          champ_id: champ.id
        }
      end

      it 'redirects to annotations page with success message' do
        expect(response).to redirect_to(annotations_instructeur_dossier_path(procedure, dossier))
        expect(flash[:notice]).to eq('Dossier Lexpol mis à jour avec succès.')
      end
    end

    context 'when dossier update fails' do
      before do
        allow(champ).to receive(:lexpol_update_dossier).and_return(false)
        allow(champ).to receive_message_chain(:errors, :full_messages).and_return(['Erreur de mise à jour'])
        post :update_dossier, params: {
          procedure_id: procedure.id,
          dossier_id: dossier.id,
          champ_id: champ.id
        }
      end

      it 'redirects to annotations page with error message' do
        expect(response).to redirect_to(annotations_instructeur_dossier_path(procedure, dossier))
        expect(flash[:alert]).to eq('Erreur de mise à jour')
      end
    end
  end
end
