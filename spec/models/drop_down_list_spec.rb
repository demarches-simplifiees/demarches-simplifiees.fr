require 'spec_helper'

describe DropDownList do

  describe 'database columns' do
    it { is_expected.to have_db_column(:value) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:type_de_champ) }
  end

  let(:dropdownlist) { create :drop_down_list, value: value }

  describe '#options' do
    let(:value) { "Cohésion sociale
Dév.Eco / Emploi
Cadre de vie / Urb.
Pilotage / Ingénierie
"
}

    it { expect(dropdownlist.options).to eq ['', 'Cohésion sociale', 'Dév.Eco / Emploi', 'Cadre de vie / Urb.', 'Pilotage / Ingénierie'] }

    context 'when one value is empty' do
      let(:value) { "Cohésion sociale

Cadre de vie / Urb.
Pilotage / Ingénierie
"
}

      it { expect(dropdownlist.options).to eq ['', 'Cohésion sociale', 'Cadre de vie / Urb.', 'Pilotage / Ingénierie'] }
    end
  end

  describe 'disabled_options' do
    let(:value) { "tip
--top--
--troupt--
ouaich"
}

    it { expect(dropdownlist.disabled_options).to match(['--top--', '--troupt--']) }
  end

  describe 'selected_options' do
    let(:dropdownlist) do
      create(:drop_down_list, type_de_champ: type_de_champ)
    end

    context 'when multiple' do
      let(:type_de_champ) { TypeDeChamp.new(type_champ: 'multiple_drop_down_list') }

      let(:champ) { Champ.new(value: '["1","2"]').decorate }
      it { expect(dropdownlist.selected_options(champ)).to match(['1', '2']) }
    end

    context 'when simple' do
      let(:type_de_champ) { TypeDeChamp.new(type_champ: 'drop_down_list') }

      let(:champ) { Champ.new(value: '1').decorate }
      it { expect(dropdownlist.selected_options(champ)).to match(['1']) }
    end
  end
end
