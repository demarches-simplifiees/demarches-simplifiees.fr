describe Champs::AddressChamp do
  let(:champ) { Champs::AddressChamp.new(value: value, data: data, type_de_champ: create(:type_de_champ_address)) }
  let(:value) { '' }
  let(:data) { nil }

  context "with value but no data" do
    let(:value) { 'Paris' }

    it { expect(champ.address_label).to eq('Paris') }
    it { expect(champ.full_address?).to be_falsey }
  end

  context "with value and data" do
    let(:value) { 'Paris' }
    let(:data) { { label: 'Paris' } }

    it { expect(champ.address_label).to eq('Paris') }
    it { expect(champ.full_address?).to be_truthy }
  end
end
