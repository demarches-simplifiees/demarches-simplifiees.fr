require 'spec_helper'

describe ChampDecorator do
  let(:champ) { create :champ, type_de_champ: (create :type_de_champ_public, type_champ: type_champ) }
  let(:decorator) { champ.decorate }

  describe 'value' do
    subject { decorator.value }

    describe 'for a checkbox' do
      let(:type_champ) { :checkbox }

      context 'when value is on' do
        before { champ.update value: 'on' }
        it { is_expected.to eq 'Oui' }
      end

      context 'when value is other' do
        it { is_expected.to eq 'Non' }
      end
    end

    describe 'for a engagement' do
      let(:type_champ) { :engagement }

      context 'when value is on' do
        before { champ.update value: 'on' }
        it { is_expected.to eq 'Oui' }
      end

      context 'when value is other' do
        it { is_expected.to eq 'Non' }
      end
    end

    describe 'for a multiple_drop_down_list' do
      let(:type_champ) { :multiple_drop_down_list }

      context 'when value is an array' do
        before { champ.update value: '["1", "2"]' }
        it { is_expected.to eq '1, 2' }
      end

      context 'when value is empty' do
        before { champ.update value: '' }
        it { is_expected.to eq '' }
      end
    end

    describe "for a date" do
      let(:type_champ) { :date }

      context "when value is an ISO date" do
        before { champ.update value: "2017-12-31" }
        it { is_expected.to eq "31/12/2017" }
      end

      context "when value is empty" do
        before { champ.update value: nil }
        it { is_expected.to eq nil }
      end
    end
  end

  describe '#date_for_input' do
    subject { decorator.date_for_input }

    describe "for a date" do
      let(:type_champ) { :date }

      context "when value is an ISO date" do
        before { champ.update value: "2017-12-31" }
        it { is_expected.to eq "2017-12-31" }
      end

      context "when value is empty" do
        before { champ.update value: nil }
        it { is_expected.to eq nil }
      end
    end

    describe "for a datetime" do
      let(:type_champ) { :date }

      context "when value is an formatted datetime" do
        before { champ.update value: "2017-12-30 23:17" }
        it { is_expected.to eq "2017-12-30" }
      end

      context "when value is empty" do
        before { champ.update value: nil }
        it { is_expected.to eq nil }
      end
    end
  end
end
