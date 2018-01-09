require 'spec_helper'

describe TypesDeChampService do
  let(:params) do
    ActionController::Parameters.new({
      procedure: {
        types_de_champ_attributes: {
          "0" => {
            libelle: 'top',
            drop_down_list_attributes: {
              value: "un\r\n       deux\r\n          -- commentaire --\r\n  trois",
              id: '5218'
            }
          }
        }
      }
    })
  end

  let(:result) { TypesDeChampService.create_update_procedure_params(params) }

  describe 'self.create_update_procedure_params' do
    describe 'the drop down list attributes' do
      subject { result['types_de_champ_attributes']['0']['drop_down_list_attributes'] }
      it 'has its value stripped' do
        expect(subject['value']).to eq("un\r\ndeux\r\n-- commentaire --\r\ntrois")
      end
    end
  end
end
