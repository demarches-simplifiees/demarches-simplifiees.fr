require 'spec_helper'

describe ChampsService do
  let(:type_de_champ) { create(:type_de_champ) }
  let(:type_de_champ_mandatory) { create(:type_de_champ, libelle: 'mandatory', mandatory: true) }
  let(:type_de_champ_datetime) { create(:type_de_champ_datetime) }
  let!(:champ) { type_de_champ.champ.create(value: 'toto') }
  let!(:champ_mandatory_empty) { type_de_champ_mandatory.champ.create }
  let!(:champ_datetime) { type_de_champ_datetime.champ.create }
  let!(:champs) { [champ, champ_mandatory_empty, champ_datetime] }

  describe 'save_champs' do
    before :each do
      params_hash = {
        champs: {
          "'#{champ.id}'" => 'yop',
          "'#{champ_datetime.id}'" => 'd'
        },
        time_hour:  { "'#{champ_datetime.id}'" => '12' },
        time_minute: { "'#{champ_datetime.id}'" => '24' }
      }
      ChampsService.save_champs(champs, params_hash)
      champs.each(&:reload)
    end

    it 'saves the changed champ' do
      expect(champ.value).to eq('yop')
    end

    it 'parses and save the date' do
      expect(champ_datetime.value).to eq(nil)
    end
  end

  describe 'build_error_message' do
    it 'adds error for the missing mandatory champ' do
      expect(ChampsService.build_error_messages(champs)).to match(['Le champ mandatory doit être rempli.'])
    end
  end
end
