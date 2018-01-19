require 'spec_helper'

describe ChampsService do
  let!(:champ) { Champ.create(value: 'toto', type_de_champ: TypeDeChamp.new) }
  let!(:champ_mandatory_empty) { Champ.create(type_de_champ: TypeDeChamp.new(libelle: 'mandatory', mandatory: true)) }
  let!(:champ_datetime) do
    champ_datetime = TypeDeChamp.new(type_champ: 'datetime')
    Champ.create(type_de_champ: champ_datetime)
  end
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
