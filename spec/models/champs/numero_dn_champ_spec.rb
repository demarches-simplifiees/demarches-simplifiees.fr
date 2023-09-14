describe Champs::NumeroDnChamp do
  let!(:dn) { '2106223' }
  let!(:ddn) { '28/11/1983' }
  let!(:iso_ddn) { '1983-11-28' }

  describe '#pack_value', vcr: { cassette_name: 'numero_dn_check' } do
    let(:champ) { described_class.new(numero_dn: dn, date_de_naissance: ddn) }

    before { champ.save }

    it { expect(champ.value).to eq("[\"#{dn}\",\"#{iso_ddn}\"]") }
  end

  describe '#to_s' do
    let(:champ) { described_class.new(numero_dn: numero_dn, date_de_naissance: date_de_naissance) }
    let(:numero_dn) { nil }
    let(:date_de_naissance) { nil }

    subject { champ.to_s }

    context 'with no value' do
      it { is_expected.to eq('') }
    end

    context 'with dn value' do
      let(:numero_dn) { dn }

      it { is_expected.to eq('') }
    end

    context 'with dn & ddn' do
      let(:numero_dn) { dn }
      let(:date_de_naissance) { ddn }

      it { is_expected.to eq("#{dn} né(e) le #{ddn}") }
    end
  end

  describe 'for_export' do
    subject { champ.for_export }

    context 'with no value' do
      let(:champ) { described_class.new }

      it { is_expected.to be_nil }
    end

    context 'with dn value' do
      let(:champ) { described_class.new(numero_dn: dn) }

      it { is_expected.to be_nil }
    end

    context 'with dn & ddn values' do
      let(:champ) { described_class.new(numero_dn: dn, date_de_naissance: ddn) }

      it { is_expected.to eq("#{dn};#{ddn}") }
    end
  end
end
