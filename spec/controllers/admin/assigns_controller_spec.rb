require 'spec_helper'

describe Admin::AssignsController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create :procedure, administrateur: admin }
  let(:instructeur) { create :instructeur, administrateurs: [admin] }

  before do
    sign_in admin
  end

  describe 'GET #show' do
    subject { get :show, params: { procedure_id: procedure.id } }
    it { expect(subject.status).to eq(200) }
  end

  describe 'PUT #update' do
    subject { put :update, params: { instructeur_id: instructeur.id, procedure_id: procedure.id, to: 'assign' } }

    it { expect(subject).to redirect_to admin_procedure_assigns_path(procedure_id: procedure.id) }

    context 'when assignement is valid' do
      before do
        subject
      end

      it { expect(flash[:notice]).to be_present }
    end
  end
end
