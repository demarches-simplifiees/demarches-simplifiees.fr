describe Champs::NumeroDnChamp do
  let!(:numero_dn) { '2106223' }
  let!(:date_de_naissance) { '28/11/1983' }
  let!(:iso_ddn) { '1983-11-28' }
  before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_numero_dn)) }

  describe '#pack_value', vcr: { cassette_name: 'numero_dn_check' } do
    let(:champ) { Champs::NumeroDnChamp.new(numero_dn:, date_de_naissance:) }

    before { champ.save }

    it { expect(champ.value).to eq("[\"#{numero_dn}\",\"#{iso_ddn}\"]") }
  end

  describe '#to_s' do
    subject { champ.to_s }

    context 'with no value' do
      let(:champ) { Champs::NumeroDnChamp.new(numero_dn: nil, date_de_naissance: nil) }
      it { is_expected.to eq('') }
    end

    context 'with dn value' do
      let(:champ) { Champs::NumeroDnChamp.new(numero_dn:, date_de_naissance: nil) }

      it { is_expected.to eq('') }
    end

    context 'with dn & ddn' do
      let(:champ) { Champs::NumeroDnChamp.new(numero_dn:, date_de_naissance:) }

      it { is_expected.to eq("#{numero_dn} né(e) le #{I18n.l(date_de_naissance.to_date, format: '%d %B %Y')}") }
    end
  end

  describe 'for_export' do
    subject { champ.for_export }

    context 'with no value' do
      let(:champ) { Champs::NumeroDnChamp.new(numero_dn: nil, date_de_naissance: nil) }
      it { is_expected.to be_nil }
    end

    context 'with dn value' do
      let(:champ) { Champs::NumeroDnChamp.new(numero_dn:, date_de_naissance: nil) }

      it { is_expected.to be_nil }
    end

    context 'with dn & ddn values' do
      let(:champ) { Champs::NumeroDnChamp.new(numero_dn:, date_de_naissance:) }

      it { is_expected.to eq(numero_dn) }
    end
  end
end
