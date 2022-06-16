describe Logic::ChampValue do
  include Logic

  subject { champ_value(champ.stable_id).compute([champ]) }

  context 'yes_no tdc' do
    let(:value) { 'true' }
    let(:champ) { create(:champ_yes_no, value: value) }

    it { expect(champ_value(champ.stable_id).type).to eq(:boolean) }

    context 'with true value' do
      it { is_expected.to be(true) }
    end

    context 'with false value' do
      let(:value) { 'false' }

      it { is_expected.to be(false) }
    end
  end

  context 'text tdc' do
    let(:champ) { create(:champ_text, value: 'text') }

    it { expect(champ_value(champ.stable_id).type).to eq(:string) }
    it { is_expected.to eq('text') }
  end

  context 'integer tdc' do
    let(:champ) { create(:champ_integer_number, value: '42') }

    it { expect(champ_value(champ.stable_id).type).to eq(:number) }
    it { is_expected.to eq(42) }
  end

  context 'decimal tdc' do
    let(:champ) { create(:champ_decimal_number, value: '42.01') }

    it { expect(champ_value(champ.stable_id).type).to eq(:number) }
    it { is_expected.to eq(42.01) }
  end

  context 'checkbox tdc' do
    let(:champ) { create(:champ_checkbox, value: 'on') }

    it { expect(champ_value(champ.stable_id).type).to eq(:boolean) }
    it { is_expected.to eq(true) }
  end

  describe 'errors' do
    let(:champ) { create(:champ) }

    it { expect(champ_value(champ.stable_id).errors([champ.stable_id])).to be_empty }
    it { expect(champ_value(champ.stable_id).errors(['other stable ids'])).to eq(["le type de champ stable_id=#{champ.stable_id} n'est pas disponible"]) }
  end
end
