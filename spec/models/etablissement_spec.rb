require 'spec_helper'

describe Etablissement do
  describe '#geo_adresse' do
    let(:etablissement) { create(:etablissement) }

    subject { etablissement.geo_adresse }

    it { is_expected.to eq '6 RUE RAOUL NORDLING IMMEUBLE BORA 92270 BOIS COLOMBES' }
  end

  describe '#inline_adresse' do
    let(:etablissement) { create(:etablissement, nom_voie: 'green    moon') }

    it { expect(etablissement.inline_adresse).to eq '6 RUE green moon, IMMEUBLE BORA, 92270 BOIS COLOMBES' }

    context 'with missing complement adresse' do
      let(:expected_adresse) { '6 RUE RAOUL NORDLING, 92270 BOIS COLOMBES' }
      subject { etablissement.inline_adresse }

      context 'when blank' do
        let(:etablissement) { create(:etablissement, complement_adresse: '') }

        it { is_expected.to eq expected_adresse }
      end

      context 'when whitespace' do
        let(:etablissement) { create(:etablissement, complement_adresse: '   ') }

        it { is_expected.to eq expected_adresse }
      end

      context 'when nil' do
        let(:etablissement) { create(:etablissement, complement_adresse: nil) }

        it { is_expected.to eq expected_adresse }
      end
    end
  end
end
