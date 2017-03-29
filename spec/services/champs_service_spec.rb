require 'spec_helper'

describe ChampsService do
  describe 'save_champs' do
    let!(:champ) { Champ.create(value: 'toto', type_de_champ: TypeDeChamp.new) }
    let!(:champ_mandatory_empty) { Champ.create(type_de_champ: TypeDeChamp.new(libelle: 'mandatory', mandatory: true)) }
    let!(:champ_datetime) do
      champ_datetime = TypeDeChamp.new(type_champ: 'datetime')
      Champ.create(type_de_champ: champ_datetime)
    end
    let!(:champs) { [champ, champ_mandatory_empty, champ_datetime] }

    before :each do
      params_hash = {
        champs: {
          "'#{champ.id}'" => 'yop',
          "'#{champ_datetime.id}'" => 'd'
        },
        time_hour:  { "'#{champ_datetime.id}'" => '12' },
        time_minute: { "'#{champ_datetime.id}'" => '24' }
      }
      @errors = ChampsService.save_champs(champs, params_hash, check_mandatory)
      champs.each(&:reload)
    end

    context 'check_mandatory is true' do
      let(:check_mandatory) { true }
      it 'saves the changed champ' do
        expect(champ.value).to eq('yop')
      end

      it 'parses and save the date' do
        expect(champ_datetime.value).to eq('d 12:24')
      end

      it 'adds error for the missing mandatory champ' do
        expect(@errors).to match([{ message: 'Le champ mandatory doit être rempli.' }])
      end
    end

    context 'check_mandatory is false' do
      let(:check_mandatory) { false }

      it 'does not add errors' do
        expect(@errors).to match([])
      end
    end
  end
end
