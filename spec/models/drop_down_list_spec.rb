require 'spec_helper'

describe DropDownList do
  describe 'database columns' do
    it { is_expected.to have_db_column(:value) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:type_de_champ) }
  end

  describe '#options' do
    let(:value) { "Cohésion sociale
Dév.Eco / Emploi
Cadre de vie / Urb.
Pilotage / Ingénierie
" }
    let(:dropdownlist) { create :drop_down_list, value: value }

    it { expect(dropdownlist.options).to eq ["Cohésion sociale", "Dév.Eco / Emploi", "Cadre de vie / Urb.", "Pilotage / Ingénierie"] }

    context 'when one value is empty' do
      let(:value) { "Cohésion sociale

Cadre de vie / Urb.
Pilotage / Ingénierie
"  }

      it { expect(dropdownlist.options).to eq ["Cohésion sociale", "Cadre de vie / Urb.", "Pilotage / Ingénierie"] }
    end
  end
end
