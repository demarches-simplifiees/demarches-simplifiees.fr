require 'spec_helper'

describe API::V1::ProceduresController do
  let(:admin) { create(:administrateur) }
  it { expect(described_class).to be < APIController }
  describe 'GET show' do
    context 'when procedure does not exist' do
      subject { get :show, id: 999_999_999, token: admin.api_token }
      it { expect(subject.status).to eq(404) }
    end
    context 'when procedure does not belong to administrateur' do
      let(:procedure) { create(:procedure, administrateur: create(:administrateur)) }
      subject { get :show, id: procedure, token: admin.api_token }
      it { expect(subject.status).to eq(404) }
    end
    context 'when procedure exist' do
      let(:procedure) { create(:procedure, administrateur: admin) }
      subject { get :show, id: procedure, token: admin.api_token }
      it { expect(subject.status).to eq(200) }
      describe 'body' do
        let(:procedure) { create(:procedure, :with_type_de_champ, :with_two_type_de_piece_justificative, administrateur: admin) }
        let(:response) { get :show, id: procedure.id, token: admin.api_token }
        subject { JSON.parse(response.body, symbolize_names: true)[:procedure] }

        it { expect(subject[:id]).to eq(procedure.id) }
        it { expect(subject[:libelle]).to eq(procedure.libelle) }
        it { expect(subject[:description]).to eq(procedure.description) }
        it { expect(subject[:organisation]).to eq(procedure.organisation) }
        it { expect(subject[:direction]).to eq(procedure.direction) }
        it { expect(subject[:lien_demarche]).to eq(procedure.lien_demarche) }
        it { expect(subject[:archived]).to eq(procedure.archived) }
        it { is_expected.to have_key(:types_de_champ) }
        it { expect(subject[:types_de_champ]).to be_an(Array) }
        describe 'type_de_champ' do
          subject { super()[:types_de_champ][0] }
          let(:champ) { procedure.types_de_champ.first }
          it { expect(subject[:id]).to eq(champ.id) }
          it { expect(subject[:libelle]).to eq(champ.libelle) }
          it { expect(subject[:type_champ]).to eq(champ.type_champ) }
          it { expect(subject[:order_place]).to eq(champ.order_place) }
          it { expect(subject[:description]).to eq(champ.description) }
        end

        it { is_expected.to have_key(:types_de_piece_justificative) }
        it { expect(subject[:types_de_piece_justificative]).to be_an(Array) }
        describe 'type_de_piece_jointe' do
          subject { super()[:types_de_piece_justificative][0] }
          let(:pj) { procedure.types_de_piece_justificative.first }
          it { expect(subject[:id]).to eq(pj.id) }
          it { expect(subject[:libelle]).to eq(pj.libelle) }
          it { expect(subject[:description]).to eq(pj.description) }
        end
      end
    end
  end
end
