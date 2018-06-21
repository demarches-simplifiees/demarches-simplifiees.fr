require 'spec_helper'

describe TypesDeChamp::LinkedDropDownListTypeDeChamp do
  describe '#unpack_options' do
    let(:drop_down_list) { build(:drop_down_list, value: menu_options) }
    let(:type_de_champ) { described_class.new(drop_down_list: drop_down_list) }

    context 'with no options' do
      let(:menu_options) { '' }
      it { expect(type_de_champ.slave_options).to eq({}) }
      it { expect(type_de_champ.master_options).to eq([]) }
    end

    context 'with two master options' do
      let(:menu_options) do
        <<~END_OPTIONS
          --Master 1--
          slave 1.1
          slave 1.2
          --Master 2--
          slave 2.1
          slave 2.2
          slave 2.3
        END_OPTIONS
      end

      it do
        expect(type_de_champ.slave_options).to eq(
          {
            '' => [],
            'Master 1' => [ '', 'slave 1.1', 'slave 1.2'],
            'Master 2' => [ '', 'slave 2.1', 'slave 2.2', 'slave 2.3']
          }
        )
      end

      it { expect(type_de_champ.master_options).to eq([ '', 'Master 1', 'Master 2' ]) }
    end
  end
end
