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

  describe '#allows_other_value?' do
    context "with options starting with Autre" do
      let(:value) do
        <<~EOS
          Autre
          Valeur 1
          Valeur 2
        EOS
      end

      it { expect(dropdownlist.options).to match(['', 'Valeur 1', 'Valeur 2']) }
      it { expect(dropdownlist.allows_other_value?).to be_truthy }
    end

    context "with options starting with Autre" do
      let(:value) do
        <<~EOS
          Autrement
          Valeur 1
          Valeur 2
        EOS
      end

      it { expect(dropdownlist.options).to match(['', 'Autrement', 'Valeur 1', 'Valeur 2']) }
      it { expect(dropdownlist.allows_other_value?).to be_falsey }
    end
  end
end
