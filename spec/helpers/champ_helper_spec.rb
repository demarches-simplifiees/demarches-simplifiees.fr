require 'rails_helper'

RSpec.describe ChampHelper, type: :helper do
  let(:type_de_champ) { create(:type_de_champ) }
  let(:champ) { type_de_champ.champ.create }

  describe '.formatted_value' do
    subject { formatted_value(champ) }

    describe 'for a checkbox' do
      let(:type_de_champ) { create(:type_de_champ_checkbox) }

      context 'when value is on' do
        before { champ.update value: 'on' }
        it { is_expected.to eq 'Oui' }
      end

      context 'when value is other' do
        it { is_expected.to eq 'Non' }
      end
    end

    describe 'for a engagement' do
      let(:type_de_champ) { create(:type_de_champ_engagement) }

      context 'when value is on' do
        before { champ.update value: 'on' }
        it { is_expected.to eq 'Oui' }
      end

      context 'when value is other' do
        it { is_expected.to eq 'Non' }
      end
    end

    describe 'for a multiple_drop_down_list' do
      let(:type_de_champ) { create(:type_de_champ_multiple_drop_down_list) }

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
      let(:type_de_champ) { create(:type_de_champ_date) }

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
end
