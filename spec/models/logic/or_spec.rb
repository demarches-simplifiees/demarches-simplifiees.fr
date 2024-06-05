describe Logic::Or do
  include Logic

  describe '#compute' do
    it { expect(or_from([true, true, true]).compute).to be true }
    it { expect(or_from([true, true, false]).compute).to be true }
    it { expect(or_from([false, false, false]).compute).to be false }
  end

  describe '#computable?' do
    let(:champ_1) { create(:champ_integer_number, value: value_1) }
    let(:champ_2) { create(:champ_integer_number, value: value_2) }

    let(:logic) do
      ds_or([
        greater_than(champ_value(champ_1.stable_id), constant(1)),
        less_than(champ_value(champ_2.stable_id), constant(10))
      ])
    end

    context 'with all champs' do
      subject { logic.computable?([champ_1, champ_2]) }

      context "when none of champs.value are filled, or logic can't be computed" do
        let(:value_1) { nil }
        let(:value_2) { nil }
        it { is_expected.to be_falsey }
      end
      context "when one champs has a value (that compute to false) the other has not, or logic keeps waiting for the 2nd value" do
        let(:value_1) { 1 }
        let(:value_2) { nil }
        it { is_expected.to be_falsey }
      end
      context 'when all champs.value are filled, or logic can be computed' do
        let(:value_1) { 1 }
        let(:value_2) { 10 }
        it { is_expected.to be_truthy }
      end
      context 'when one champs.value and his condition is true, or logic can be computed' do
        let(:value_1) { 2 }
        let(:value_2) { nil }
        it { is_expected.to be_truthy }
      end
      context 'when one champs is not visible and the other has a value that fails, or logic can be computed' do
        let(:value_1) { 1 }
        let(:value_2) { nil }
        before { expect(champ_2).to receive(:visible?).and_return(false) }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#to_s' do
    it { expect(or_from([true, false, true]).to_s).to eq "(Oui || Non || Oui)" }
  end

  def or_from(boolean_to_constants)
    ds_or(boolean_to_constants.map { |b| constant(b) })
  end
end
