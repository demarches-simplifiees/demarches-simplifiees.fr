require 'spec_helper'

describe Champs::CheckboxChamp do
  let(:checkbox) { Champs::CheckboxChamp.new(value: value) }

  describe '#to_s' do
    subject { checkbox.to_s }

    context 'when the value is on' do
      let(:value) { 'on' }

      it { is_expected.to eq('oui') }
    end

    context 'when the value is off' do
      let(:value) { 'off' }

      it { is_expected.to eq('non') }
    end
  end
end
