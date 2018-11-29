require 'spec_helper'

describe Champs::IntegerNumberChamp do
  subject { Champs::IntegerNumberChamp.new(value: value) }

  describe '#valid?' do
    context 'when the value is integer number' do
      let(:value) { 2 }

      it { is_expected.to be_valid }
    end

    context 'when the value is decimal number' do
      let(:value) { 2.6 }

      it { is_expected.to_not be_valid }
    end

    context 'when the value is not a number' do
      let(:value) { 'toto' }

      it { is_expected.to_not be_valid }
    end

    context 'when the value is blank' do
      let(:value) { '' }

      it { is_expected.to be_valid }
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it { is_expected.to be_valid }
    end
  end
end
