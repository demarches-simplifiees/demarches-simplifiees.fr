require 'spec_helper'

describe ChampDecorator do
  let(:champ) {create :champ, type_de_champ: (create :type_de_champ_public, type_champ: :checkbox)}
  let(:decorator) { champ.decorate }

  describe 'value' do
    subject { decorator.value }

    context 'when type_champ is checkbox' do

      context 'when value is on' do
        before do
          champ.update value: 'on'
        end

        it { is_expected.to eq 'Oui' }
      end

      context 'when value is other' do
        it { is_expected.to eq 'Non' }
      end
    end
  end
end
