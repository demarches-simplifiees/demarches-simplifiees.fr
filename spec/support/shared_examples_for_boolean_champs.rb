# frozen_string_literal: true

RSpec.shared_examples "a boolean champ" do
  describe 'before validation' do
    subject { boolean_champ.valid? }

    context "when the value is blank" do
      let(:value) { "" }

      it "normalizes the value to nil" do
        expect { subject }.to change { boolean_champ.value }.from(value).to(nil)
      end
    end

    context "when the value is something else" do
      let(:value) { "something else" }

      it "normalizes the value to 'false'" do
        expect { subject }.to change { boolean_champ.value }.from(value).to(Champs::BooleanChamp::FALSE_VALUE)
      end
    end
  end

  describe '#true?' do
    subject { boolean_champ.true? }

    context "when the checkbox value is 'true'" do
      let(:value) { 'true' }

      it { is_expected.to eq(true) }
    end

    context "when the checkbox value is 'false'" do
      let(:value) { 'false' }

      it { is_expected.to eq(false) }
    end
  end

  describe '#to_s' do
    subject { boolean_champ.to_s }

    context 'when the value is false' do
      let(:value) { 'false' }

      it { is_expected.to eq('Non') }
    end

    context 'when the value is true' do
      let(:value) { 'true' }

      it { is_expected.to eq('Oui') }
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it { is_expected.to eq("Non") }
    end
  end
end
