require 'spec_helper'

describe TypesDeChamp::LinkedDropDownListTypeDeChamp do
  describe '#unpack_options' do
    let(:drop_down_list) { build(:drop_down_list, value: menu_options) }
    let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list, drop_down_list: drop_down_list) }

    subject { type_de_champ.dynamic_type }

    context 'with no options' do
      let(:menu_options) { '' }
      it { expect(subject.secondary_options).to eq({}) }
      it { expect(subject.primary_options).to eq([]) }
    end

    context 'with two primary options' do
      let(:menu_options) do
        <<~END_OPTIONS
          --Primary 1--
          secondary 1.1
          secondary 1.2
          --Primary 2--
          secondary 2.1
          secondary 2.2
          secondary 2.3
        END_OPTIONS
      end

      it do
        expect(subject.secondary_options).to eq(
          {
            '' => [],
            'Primary 1' => [ '', 'secondary 1.1', 'secondary 1.2'],
            'Primary 2' => [ '', 'secondary 2.1', 'secondary 2.2', 'secondary 2.3']
          }
        )
      end

      it { expect(subject.primary_options).to eq([ '', 'Primary 1', 'Primary 2' ]) }
    end
  end
end
