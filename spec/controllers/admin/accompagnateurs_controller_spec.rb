require 'spec_helper'

describe Admin::AccompagnateursController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create :procedure, administrateur: admin }
  let(:gestionnaire) { create :gestionnaire, administrateurs: [admin] }

  before do
    sign_in admin
  end

  describe 'GET #show' do
    subject { get :show, params: {procedure_id: procedure.id} }
    it { expect(subject.status).to eq(200) }
  end

  describe 'PUT #update' do
    subject { put :update, params: {accompagnateur_id: gestionnaire.id, procedure_id: procedure.id, to: 'assign'} }

    it { expect(subject).to redirect_to admin_procedure_accompagnateurs_path(procedure_id: procedure.id) }

    context 'when assignement is valid' do
      before do
        subject
      end

      it { expect(flash[:notice]).to be_present }

      it 'default pref list dossier procedure columns are created' do
        expect(procedure.preference_list_dossiers.size).to eq gestionnaire.preference_list_dossiers.where('procedure_id IS NULL').size
      end
    end
  end
end