describe Logic::InRegionOperator do
  include Logic

  let(:champ_commune) { create(:champ_communes, code_postal: '92500', external_id: '92063') }
  let(:champ_epci) { create(:champ_epci, code_departement: '02', code_region: "32") }
  let(:champ_departement) { create(:champ_departements, value: '01', code_region: '84') }

  describe '#compute' do
    context 'commune' do
      it { expect(ds_in_region(champ_value(champ_commune.stable_id), constant('11')).compute([champ_commune])).to be(true) }
    end

    context 'epci' do
      it do
        champ_epci.update_columns(external_id: "200071991", value: "CC Retz en Valois")
        expect(ds_in_region(champ_value(champ_epci.stable_id), constant('32')).compute([champ_epci])).to be(true)
      end
    end

    context 'departement' do
      it { expect(ds_in_region(champ_value(champ_departement.stable_id), constant('84')).compute([champ_departement])).to be(true) }
    end
  end
end
