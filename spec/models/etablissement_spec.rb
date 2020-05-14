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

  describe '.entreprise_bilans_bdf_to_csv' do
    let(:etablissement) { build(:etablissement, entreprise_bilans_bdf: bilans) }
    let(:bilans) do
      [
        {
          "total_passif": "1200",
          "chiffres_affaires_ht": "40000"
        },
        {
          "total_passif": "0",
          "evolution_total_dettes_stables": "30"
        }
      ]
    end

    subject { etablissement.entreprise_bilans_bdf_to_csv.split("\n") }

    it "build a csv with all keys" do
      expect(subject[0].split(',').sort).to eq(["total_passif", "chiffres_affaires_ht", "evolution_total_dettes_stables"].sort)
      expect(subject[1].split(',')).to eq(["1200", "40000"])
      expect(subject[2].split(',')).to eq(["0", "", "30"])
    end
  end
end
