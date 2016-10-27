shared_examples 'champ_spec' do
  describe 'database columns' do
    it { is_expected.to have_db_column(:value) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dossier) }
    it { is_expected.to belong_to(:type_de_champ) }
  end

  describe 'delegation' do
    it { is_expected.to delegate_method(:libelle).to(:type_de_champ) }
    it { is_expected.to delegate_method(:type_champ).to(:type_de_champ) }
    it { is_expected.to delegate_method(:order_place).to(:type_de_champ) }
  end

  describe 'data_provide' do
    let(:champ) { create :champ }

    subject { champ.data_provide }

    context 'when type_champ is datetime' do
      before do
        champ.type_de_champ = create :type_de_champ_public, type_champ: 'datetime'
      end

      it { is_expected.to eq 'datepicker' }
    end

    context 'when type_champ is address' do
      before do
        champ.type_de_champ = create :type_de_champ_public, type_champ: 'address'
      end

      it { is_expected.to eq 'typeahead' }
    end
  end

  describe '.departement', vcr: {cassette_name: 'call_geo_api_departements'} do
    subject { Champ.departements }

    it { expect(subject).to include '99 - Étranger' }
  end
end