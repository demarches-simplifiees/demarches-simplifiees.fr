require 'spec_helper'

describe TypesDeChampService do
  let(:params) { ActionController::Parameters.new({ procedure: { types_de_champ_attributes: types_de_champ_attributes } }) }
  let(:procedure) { create(:procedure) }
  let(:service) { TypesDeChampService.new(procedure) }

  describe 'create_update_procedure_params' do
    let(:result) { service.create_update_procedure_params(params) }

    describe 'the drop down list attributes' do
      let(:types_de_champ_attributes) do
        {
          "0": {
            libelle: 'top',
            drop_down_list_attributes: {
              value: "un\r\n       deux\r\n          -- commentaire --\r\n  trois",
              id: '5218'
            }
          }
        }
      end

      subject { result['types_de_champ_attributes']['0']['drop_down_list_attributes'] }
      it 'has its value stripped' do
        expect(subject['value']).to eq("un\r\ndeux\r\n-- commentaire --\r\ntrois")
      end
    end

    describe 'reorder the fields' do
      let(:types_de_champ_attributes) do
        {
          '0': { 'libelle': 'a', 'order_place': '0', 'custom_order_place': '1' },
          '1': { 'libelle': 'b', 'order_place': '1', 'custom_order_place': '2' }
        }
      end

      subject { result['types_de_champ_attributes'].to_unsafe_hash }

      it do
        is_expected.to match({
          '0': { 'libelle': 'a', 'order_place': '0', 'private': false },
          '1': { 'libelle': 'b', 'order_place': '1', 'private': false }
        })
      end

      context 'when the user specifies a position on one element' do
        let(:types_de_champ_attributes) do
          {
            '0': { 'libelle': 'a', 'order_place': '1', 'custom_order_place': '1' },
            '1': { 'libelle': 'b', 'order_place': '10', 'custom_order_place': '10' },
            '2': { 'libelle': 'c', 'order_place': '11', 'custom_order_place': '2' }
          }
        end

        it do
          is_expected.to match({
            '0': { 'libelle': 'a', 'order_place': '0', 'private': false },
            '1': { 'libelle': 'c', 'order_place': '1', 'private': false },
            '2': { 'libelle': 'b', 'order_place': '2', 'private': false }
          })
        end
      end

      context 'when the user puts a champ down' do
        let(:types_de_champ_attributes) do
          {
            '0': { 'libelle': 'a', 'order_place': '0', 'custom_order_place': '2' },
            '1': { 'libelle': 'b', 'order_place': '1', 'custom_order_place': '2' },
            '2': { 'libelle': 'c', 'order_place': '2', 'custom_order_place': '3' }
          }
        end

        it do
          is_expected.to match({
            '0': { 'libelle': 'b', 'order_place': '0', 'private': false },
            '1': { 'libelle': 'a', 'order_place': '1', 'private': false },
            '2': { 'libelle': 'c', 'order_place': '2', 'private': false }
          })
        end
      end

      context 'when the user uses not a number' do
        let(:types_de_champ_attributes) do
          {
            '0': { 'libelle': 'a', 'order_place': '0', 'custom_order_place': '1' },
            '1': { 'libelle': 'b', 'order_place': '1', 'custom_order_place': '2' },
            '2': { 'libelle': 'c', 'order_place': '2', 'custom_order_place': '' },
            '3': { 'libelle': 'd', 'order_place': '3', 'custom_order_place': 'a' }
          }
        end

        it 'does not change the natural order' do
          is_expected.to match({
            '0': { 'libelle': 'a', 'order_place': '0', 'private': false },
            '1': { 'libelle': 'b', 'order_place': '1', 'private': false },
            '2': { 'libelle': 'c', 'order_place': '2', 'private': false },
            '3': { 'libelle': 'd', 'order_place': '3', 'private': false }
          })
        end
      end
    end
  end

  describe ".options" do
    let(:pj_option) { ["Pièce justificative", TypeDeChamp.type_champs.fetch(:piece_justificative)] }

    subject { service.options }

    it { is_expected.to include(pj_option) }
  end
end
