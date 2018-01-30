require 'spec_helper'

describe DropDownList do
  let(:dropdownlist) { create :drop_down_list, value: value }

  describe '#options' do
    let(:value) do
      <<~EOS
        Cohésion sociale
        Dév.Eco / Emploi
        Cadre de vie / Urb.
        Pilotage / Ingénierie
      EOS
    end

    it { expect(dropdownlist.options).to eq ['', 'Cohésion sociale', 'Dév.Eco / Emploi', 'Cadre de vie / Urb.', 'Pilotage / Ingénierie'] }

    context 'when one value is empty' do
      let(:value) do
        <<~EOS
          Cohésion sociale
          Cadre de vie / Urb.
          Pilotage / Ingénierie
        EOS
      end

      it { expect(dropdownlist.options).to eq ['', 'Cohésion sociale', 'Cadre de vie / Urb.', 'Pilotage / Ingénierie'] }
    end
  end

  describe 'disabled_options' do
    let(:value) do
      <<~EOS
        tip
        --top--
        --troupt--
        ouaich
      EOS
    end

    it { expect(dropdownlist.disabled_options).to match(['--top--', '--troupt--']) }
  end

  describe 'selected_options' do
    let(:dropdownlist) do
      create(:drop_down_list, type_de_champ: type_de_champ)
    end

    context 'when multiple' do
      let(:type_de_champ) { TypeDeChamp.new(type_champ: 'multiple_drop_down_list') }

      let(:champ) { Champ.new(type_de_champ: type_de_champ, value: '["1","2"]').decorate }
      it { expect(dropdownlist.selected_options(champ)).to match(['1', '2']) }
    end

    context 'when simple' do
      let(:type_de_champ) { TypeDeChamp.new(type_champ: 'drop_down_list') }

      let(:champ) { Champ.new(type_de_champ: type_de_champ, value: '1').decorate }
      it { expect(dropdownlist.selected_options(champ)).to match(['1']) }
    end
  end
end
