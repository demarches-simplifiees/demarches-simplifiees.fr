describe Logic::InDepartementOperator do
  include Logic

  let(:champ_commune) { create(:champ_communes, code_postal: '92500', external_id: '92063') }
  let(:champ_epci) { create(:champ_epci, code_departement: '02', code_region: "32") }

  describe '#compute' do
    context 'commune' do
      it { expect(ds_in_departement(champ_value(champ_commune.stable_id), constant('92')).compute([champ_commune])).to be(true) }
    end

    context 'epci' do
      it do
        champ_epci.update_columns(external_id: "200071991", value: "CC Retz en Valois")
        expect(ds_in_departement(champ_value(champ_epci.stable_id), constant('02')).compute([champ_epci])).to be(true)
      end
    end
  end
end
