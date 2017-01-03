require 'spec_helper'

describe Admin::TypesDeChampPrivateController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, administrateur: admin) }

  before do
    sign_in admin
  end

  describe 'GET #show' do
    let(:published) { false }
    let(:procedure) { create(:procedure, administrateur: admin, published: published) }
    let(:procedure_id) { procedure.id }

    subject { get :show, params: {procedure_id: procedure_id} }

    context 'when procedure is not found' do
      let(:procedure_id) { 9_999_999 }
      it { expect(subject.status).to eq(404) }
    end

    context 'when procedure is published' do
      let(:published) { true }
      it { is_expected.to redirect_to admin_procedure_path id: procedure_id }
    end

    context 'when procedure does not belong to admin' do
      let(:admin_2) { create(:administrateur) }
      let(:procedure) { create(:procedure, administrateur: admin_2) }
      it { expect(subject.status).to eq(404) }
    end
  end

  describe '#update' do
    let(:libelle) { 'mon libelle' }
    let(:type_champ) { 'text' }
    let(:description) { 'titi' }
    let(:order_place) { '' }
    let(:types_de_champ_id) { '' }
    let(:mandatory) { 'on' }

    let(:procedure_params) do
      {types_de_champ_private_attributes:
           {'0' =>
                {
                    libelle: libelle,
                    type_champ: type_champ,
                    description: description,
                    order_place: order_place,
                    id: types_de_champ_id,
                    mandatory: mandatory,
                    type: 'TypeDeChampPrivate'
                },
            '1' =>
                {
                    libelle: '',
                    type_champ: 'text',
                    description: '',
                    order_place: '1',
                    id: '',
                    mandatory: false,
                    type: 'TypeDeChampPrivate'
                }
           }
      }
    end

    let(:request) { put :update, params: {format: :js, procedure_id: procedure.id, procedure: procedure_params} }

    context 'when procedure is found' do
      it { expect { request }.to change(TypeDeChamp, :count).by(1) }

      describe 'created type de champ' do
        before do
          request
          procedure.reload
        end
        subject { procedure.types_de_champ_private.first }

        it { expect(subject.libelle).to eq('mon libelle') }
        it { expect(subject.type_champ).to eq('text') }
        it { expect(subject.description).to eq('titi') }
        it { expect(subject.mandatory).to be_truthy }
      end

      context 'when type_de_champ already exist' do
        let(:procedure) { create(:procedure, :with_type_de_champ_private, administrateur: admin) }
        let(:type_de_champ) { procedure.types_de_champ_private.first }
        let(:types_de_champ_id) { type_de_champ.id }
        let(:libelle) { 'toto' }
        let(:type_champ) { 'text' }
        let(:description) { 'citrouille' }
        let(:order_place) { '0' }
        let(:mandatory) { 'on' }
        before do
          request
          procedure.reload
        end
        subject { procedure.types_de_champ_private.first }
        it { expect(subject.libelle).to eq('toto') }
        it { expect(subject.type_champ).to eq('text') }
        it { expect(subject.description).to eq('citrouille') }
        it { expect(subject.order_place).to eq(0) }
        it { expect(subject.order_place).to be_truthy }
      end
    end
    context 'when procedure is not found' do
      subject { put :update, params: {format: :js, procedure_id: 9_999_999, procedure: procedure_params} }
      it 'creates type de champ' do
        expect(subject.status).to eq(404)
      end
    end
  end

  describe '#destroy' do
    before do
      delete :destroy, params: {procedure_id: procedure.id, id: type_de_champ_id, format: :js}
    end

    context 'when type de champs does not exist' do
      let(:type_de_champ_id) { 99999999 }
      it { expect(subject.status).to eq(404) }
    end
    context 'when types_de_champ exists' do
      let(:procedure) { create(:procedure, :with_type_de_champ_private, administrateur: admin) }
      let(:type_de_champ_id) { procedure.types_de_champ_private.first.id }
      it { expect(subject.status).to eq(200) }
      it 'destroy type de champ' do
        procedure.reload
        expect(procedure.types_de_champ.count).to eq(0)
      end
    end
    context 'when procedure and type de champs are not linked' do
      let(:type_de_champ) { create(:type_de_champ_public) }
      let(:type_de_champ_id) { type_de_champ.id }
      it { expect(subject.status).to eq(404) }
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
      let!(:type_de_champ) { create(:type_de_champ_private, procedure: procedure) }
      it { expect(subject.status).to eq(400) }
    end
    context 'when procedure have tow type de champs' do
      context 'when index == 0' do
        let(:index) { 0 }
        let!(:type_de_champ_1) { create(:type_de_champ_private, procedure: procedure) }
        let!(:type_de_champ_2) { create(:type_de_champ_private, procedure: procedure) }
        it { expect(subject.status).to eq(400) }
      end
      context 'when index > 0' do
        let(:index) { 1 }
        let!(:type_de_champ_0) { create(:type_de_champ_private, procedure: procedure, order_place: 0) }
        let!(:type_de_champ_1) { create(:type_de_champ_private, procedure: procedure, order_place: 1) }

        it { expect(subject.status).to eq(200) }
        it { expect(subject).to render_template('show') }
        it 'changes order places' do
          post :move_up, params: {procedure_id: procedure.id, index: index, format: :js}
          type_de_champ_0.reload
          type_de_champ_1.reload
          expect(type_de_champ_0.order_place).to eq(1)
          expect(type_de_champ_1.order_place).to eq(0)
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
      let!(:type_de_champ_0) { create(:type_de_champ_private, procedure: procedure) }
      it { expect(subject.status).to eq(400) }
    end
    context 'when procedure have 2 type de champ' do
      let!(:type_de_champ_0) { create(:type_de_champ_private, procedure: procedure, order_place: 0) }
      let!(:type_de_champ_1) { create(:type_de_champ_private, procedure: procedure, order_place: 1) }
      context 'when index represent last type_de_champ' do
        let(:index) { 1 }
        it { expect(subject.status).to eq(400) }
      end
      context 'when index does not represent last type_de_champ' do
        let(:index) { 0 }
        it { expect(subject.status).to eq(200) }
        it { expect(subject).to render_template('show') }
        it 'changes order place' do
          request
          type_de_champ_0.reload
          type_de_champ_1.reload
          expect(type_de_champ_0.order_place).to eq(1)
          expect(type_de_champ_1.order_place).to eq(0)
        end
      end
    end
  end
end
