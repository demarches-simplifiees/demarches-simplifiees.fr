require 'spec_helper'

describe Admin::PiecesJustificativesController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:published_at) { nil }
  let(:procedure) { create(:procedure, administrateur: admin, published_at: published_at) }
  before do
    sign_in admin
  end

  describe 'GET #show' do
    let(:procedure_id) { procedure.id }

    subject { get :show, params: {procedure_id: procedure_id} }

    context 'when procedure is not found' do
      let(:procedure_id) { 9_999_999 }
      it { expect(subject.status).to eq(404) }
    end

    context 'when procedure is published' do
      let(:published_at) { Time.now }
      it { is_expected.to redirect_to admin_procedure_path id: procedure_id }
    end

    context 'when procedure does not belong to admin' do
      let(:admin_2) { create(:administrateur) }
      let(:procedure) { create(:procedure, administrateur: admin_2) }
      it { expect(subject.status).to eq(404) }
    end
  end

  describe 'PUT #update' do
    let(:procedure_id) { procedure.id }
    let(:libelle) { 'RIB' }
    let(:description) { "relevé d'identité bancaire" }
    let(:update_params) do
      {
          types_de_piece_justificative_attributes:
              {
                  '0' =>
                      {
                          libelle: libelle,
                          description: description
                      }
              }
      }
    end

    let(:request) { put :update, params: {procedure_id: procedure_id, format: :js, procedure: update_params} }
    subject { request }

    it { is_expected.to render_template('show') }
    it { expect { subject }.to change(TypeDePieceJustificative, :count).by(1) }
    it 'adds type de pj to procedure' do
      request
      procedure.reload
      pj = procedure.types_de_piece_justificative.first
      expect(pj.libelle).to eq(libelle)
      expect(pj.description).to eq(description)
    end

    context 'when procedure is not found' do
      let(:procedure_id) { 9_999_999 }
      it { expect(subject.status).to eq(404) }
    end

    context 'when libelle is blank' do
      let(:libelle) { '' }
      it { expect { subject }.not_to change(TypeDePieceJustificative, :count) }
    end
  end

  describe 'DELETE #destroy' do
    let!(:pj) { create(:type_de_piece_justificative, procedure: procedure) }
    let(:procedure_id) { procedure.id }
    let(:pj_id) { pj.id }
    let(:request) { delete :destroy, params: {procedure_id: procedure_id, id: pj_id} }
    subject { request }
    context 'when procedure is not found' do
      let(:procedure_id) { 9_999_999 }
      it { expect(subject.status).to eq(404) }
    end
    context 'when pj id does not exist' do
      let(:pj_id) { 9_999_999 }
      it { expect(subject.status).to eq(404) }
    end
    context 'when pj id exist but is not linked to procedure' do
      let(:procedure_1) { create(:procedure, administrateur: admin) }
      let!(:pj_1) { create(:type_de_piece_justificative, procedure: procedure_1) }
      let(:pj_id) { pj_1 }
      it { expect(subject.status).to eq(404) }
    end
    context 'when pj is found' do
      it { expect(subject.status).to eq(200) }
      it { expect { subject }.to change(TypeDePieceJustificative, :count).by(-1) }
    end
  end

  describe 'POST #move_up' do
    subject { post :move_up, params: {procedure_id: procedure.id, index: index, format: :js} }

    context 'when procedure have no type de champ' do
      let(:index) { 0 }
      it { expect(subject.status).to eq(400) }
    end
    context 'when procedure have only one type de champ' do
      let(:index) { 1 }
      let!(:type_de_piece_justificative) { create(:type_de_piece_justificative, procedure: procedure) }
      it { expect(subject.status).to eq(400) }
    end
    context 'when procedure have tow type de champs' do
      context 'when index == 0' do
        let(:index) { 0 }
        let!(:type_de_piece_justificative_1) { create(:type_de_piece_justificative, procedure: procedure) }
        let!(:type_de_piece_justificative_2) { create(:type_de_piece_justificative, procedure: procedure) }
        it { expect(subject.status).to eq(400) }
      end
      context 'when index > 0' do
        let(:index) { 1 }
        let!(:type_de_piece_justificative_0) { create(:type_de_piece_justificative, procedure: procedure, order_place: 0) }
        let!(:type_de_piece_justificative_1) { create(:type_de_piece_justificative, procedure: procedure, order_place: 1) }

        it { expect(subject.status).to eq(200) }
        it { expect(subject).to render_template('show') }
        it 'changes order places' do
          post :move_up, params: {procedure_id: procedure.id, index: index, format: :js}
          type_de_piece_justificative_0.reload
          type_de_piece_justificative_1.reload
          expect(type_de_piece_justificative_0.order_place).to eq(1)
          expect(type_de_piece_justificative_1.order_place).to eq(0)
        end
      end
    end
  end

  describe 'POST #move_down' do
    let(:request) { post :move_down, params: {procedure_id: procedure.id, index: index, format: :js} }
    let(:index) { 0 }

    subject { request }

    context 'when procedure have no type de champ' do
      it { expect(subject.status).to eq(400) }
    end
    context 'when procedure have only one type de champ' do
      let!(:type_de_piece_justificative_0) { create(:type_de_piece_justificative, procedure: procedure) }
      it { expect(subject.status).to eq(400) }
    end
    context 'when procedure have 2 type de champ' do
      let!(:type_de_piece_justificative_0) { create(:type_de_piece_justificative, procedure: procedure, order_place: 0) }
      let!(:type_de_piece_justificative_1) { create(:type_de_piece_justificative, procedure: procedure, order_place: 1) }
      context 'when index represent last type_de_piece_justificative' do
        let(:index) { 1 }
        it { expect(subject.status).to eq(400) }
      end
      context 'when index does not represent last type_de_piece_justificative' do
        let(:index) { 0 }
        it { expect(subject.status).to eq(200) }
        it { expect(subject).to render_template('show') }
        it 'changes order place' do
          request
          type_de_piece_justificative_0.reload
          type_de_piece_justificative_1.reload
          expect(type_de_piece_justificative_0.order_place).to eq(1)
          expect(type_de_piece_justificative_1.order_place).to eq(0)
        end
      end
    end
  end
end
