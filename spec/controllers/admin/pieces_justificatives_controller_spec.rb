require 'spec_helper'

describe Admin::PiecesJustificativesController, type: :controller  do
  let(:admin) { create(:administrateur) }
  before do
    sign_in admin
  end

  describe 'GET #show' do
    let(:procedure) { create(:procedure, administrateur: admin) }
    let(:procedure_id) { procedure.id }
    subject { get :show, procedure_id: procedure_id }
    context 'when procedure is not found' do
      let(:procedure_id) { 9_999_999 }
      it { expect(subject.status).to eq(404) }
    end
    context 'when procedure does not belong to admin' do
      let(:admin_2) { create(:administrateur) }
      let(:procedure) { create(:procedure, administrateur: admin_2) }
      it { expect(subject.status).to eq(404) }
    end
  end

  describe 'POST #update' do
    let(:procedure) { create(:procedure, administrateur: admin) }
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

    let(:request) { put :update, procedure_id: procedure_id, format: :js, procedure: update_params }
    subject { request }

    it { is_expected.to render_template('show') }
    it { expect{ subject }.to change(TypeDePieceJustificative, :count).by(1) }
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
      it { expect{ subject }.not_to change(TypeDePieceJustificative, :count) }
    end
  end
end