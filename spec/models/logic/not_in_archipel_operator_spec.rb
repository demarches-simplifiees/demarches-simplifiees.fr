# frozen_string_literal: true

describe Logic::NotInArchipelOperator do
  include Logic

  let(:dossier) { create(:dossier) }
  let(:champ_commune_de_polynesie) { Champs::CommuneDePolynesieChamp.new(dossier:, value: 'Mangareva - 98755').tap(&:save!) }
  let(:champ_code_postal_de_polynesie) { Champs::CodePostalDePolynesieChamp.new(dossier:, value: '98755 - Mangareva').tap(&:save!) }
  before do
    allow(champ_commune_de_polynesie).to receive(:type_de_champ).and_return(build(:type_de_champ_commune_de_polynesie))
    allow(champ_code_postal_de_polynesie).to receive(:type_de_champ).and_return(build(:type_de_champ_code_postal_de_polynesie))
  end

  describe '#compute' do
    context 'commune_de_polynesie' do
      it do
        expect(ds_not_in_archipel(champ_value(champ_commune_de_polynesie.stable_id), constant('Marquise')).compute([champ_commune_de_polynesie])).to be(true)
        expect(ds_not_in_archipel(champ_value(champ_commune_de_polynesie.stable_id), constant('Tuamotu-Gambiers')).compute([champ_commune_de_polynesie])).to be(false)
      end
    end

    context 'code_postal_de_polynesie' do
      it do
        champ_code_postal_de_polynesie.update(value: '98735 - Fetuna - Raiatea')
        expect(ds_not_in_archipel(champ_value(champ_code_postal_de_polynesie.stable_id), constant('Iles Sous Le Vent')).compute([champ_code_postal_de_polynesie])).to be(false)
        expect(ds_not_in_archipel(champ_value(champ_code_postal_de_polynesie.stable_id), constant('Tuamotu-Gambiers')).compute([champ_code_postal_de_polynesie])).to be(true)
      end
    end
  end
end
