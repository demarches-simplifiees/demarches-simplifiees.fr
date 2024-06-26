describe Logic::NotInDepartementOperator do
  include Logic

  let(:champ_commune) { create(:champ_communes, code_postal: '92500', external_id: '92063') }
  let(:champ_epci) { create(:champ_epci, code_departement: '02', code_region: "32") }

  describe '#compute' do
    context 'commune' do
      it do
        expect(ds_not_in_departement(champ_value(champ_commune.stable_id), constant('93')).compute([champ_commune])).to be(true)
        expect(ds_not_in_departement(champ_value(champ_commune.stable_id), constant('92')).compute([champ_commune])).to be(false)
      end
    end

    context 'epci' do
      it do
        champ_epci.update_columns(external_id: "200071991", value: "CC Retz en Valois")
        expect(ds_not_in_departement(champ_value(champ_epci.stable_id), constant('02')).compute([champ_epci])).to be(false)
        expect(ds_not_in_departement(champ_value(champ_epci.stable_id), constant('03')).compute([champ_epci])).to be(true)
      end
    end
  end

  describe '#to_query' do
    let(:stable_id) { 2 }
    let(:value) { 'abc' }
    it { expect(ds_not_in_departement(champ_value(stable_id), constant(value)).to_query([]).to_sql).to eq(Champ.where(stable_id:).where(Champ.arel_table[:external_id].not_eq(value)).to_sql) }
  end
end
