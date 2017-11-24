require 'spec_helper'

describe ChampDecorator do
  let(:champ) {create :champ, type_de_champ: (create :type_de_champ_public, type_champ: type_champ)}
  let(:decorator) { champ.decorate }

  describe 'value' do
    subject { decorator.value }

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
end
