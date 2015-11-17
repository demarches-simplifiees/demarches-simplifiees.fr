require 'spec_helper'

describe Admin::TypesDeChampController, type: :controller do
  let(:admin) { create(:administrateur) }
  before do
    sign_in admin
  end

  describe '#update' do
    let(:procedure) { create(:procedure) }
    let(:libelle) { 'mon libelle' }
    let(:type_champ) { 'text' }
    let(:description) { 'titi' }
    let(:order_place) { '' }
    let(:types_de_champ_id) { '' }

    let(:procedure_params) do
      { types_de_champ_attributes:
        { '0' =>
          {
            libelle: libelle,
            type_champ: type_champ,
            description: description,
            order_place: order_place,
            id: types_de_champ_id
          }
        }
      }
    end

    let(:request) { put :update, format: :js, procedure_id: procedure.id, procedure: procedure_params }

    context 'when procedure is found' do
      it { expect{ request }.to change(TypeDeChamp, :count).by(1) }

      describe 'created type de champ' do
        before do
          request
          procedure.reload
        end
        subject { procedure.types_de_champ.first }

        it { expect(subject.libelle).to eq('mon libelle') }
        it { expect(subject.type_champ).to eq('text') }
        it { expect(subject.description).to eq('titi') }
        # it { expect(subject.order_place).to eq('0') }
      end

      context 'when type_de_champ already exist' do
        let(:procedure) { create(:procedure, :with_type_de_champ) }
        let(:type_de_champ) { procedure.types_de_champ.first }
        let(:types_de_champ_id) { type_de_champ.id }
        let(:libelle) { 'toto' }
        let(:type_champ) { 'text' }
        let(:description) { 'citrouille' }
        let(:order_place) { '0' }
        before do
          request
          procedure.reload
        end
        subject { procedure.types_de_champ.first }
        it { expect(subject.libelle).to eq('toto') }
        it { expect(subject.type_champ).to eq('text') }
        it { expect(subject.description).to eq('citrouille') }
        # it { expect(subject.order_place).to eq(0) }
      end
    end
    context 'when procedure is not found' do
      subject { put :update, format: :js, procedure_id: 9_999_999, procedure: procedure_params }
      it 'creates type de champ' do
        expect(subject.status).to eq(404)
      end
    end
  end

  describe '#destroy' do
    before do
      delete :destroy, procedure_id: procedure.id, id: type_de_champ_id
    end
    context 'when type de champs does not exist' do
      let(:type_de_champ_id) { 99999999 }
      let(:procedure) { create(:procedure) }
      it { expect(subject.status).to eq(404) }
    end
    context 'when types_de_champ exists' do
      let(:procedure) { create(:procedure, :with_type_de_champ) }
      let(:type_de_champ_id) { procedure.types_de_champ.first.id }
      it { expect(subject.status).to eq(200) }
      it 'destroy type de champ' do
        procedure.reload
        expect(procedure.types_de_champ.count).to eq(0)
      end
    end
    context 'when procedure and type de champs are not linked' do
      let(:procedure) { create(:procedure) }
      let(:type_de_champ) { create(:type_de_champ) }
      let(:type_de_champ_id) { type_de_champ.id }
      it { expect(subject.status).to eq(404) }
    end
  end
end
