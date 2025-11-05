# frozen_string_literal: true

RSpec.describe EtablissementHelper, type: :helper do
  let(:code_effectif) { '00' }
  let(:raison_sociale) { 'GRTGaz' }
  let(:enseigne) { "mon enseigne" }
  let(:nom) { 'mon nom' }
  let(:prenom) { 'mon prenom' }
  let(:etat_administratif) { 'actif' }
  let(:etablissement_params) do
    {
      enseigne: enseigne,
      entreprise_capital_social: 123_000,
      entreprise_code_effectif_entreprise: code_effectif,
      entreprise_raison_sociale: raison_sociale,
      entreprise_etat_administratif: etat_administratif,
      entreprise_nom: nom,
      entreprise_prenom: prenom,
    }
  end
  let(:etablissement) { create(:etablissement, etablissement_params) }

  describe "#pretty_siret" do
    subject { pretty_siret("12345678900001") }

    it { is_expected.to eq("123 456 789 00001") }
  end

  describe "#extract_resultat_exercice" do
    let(:bilan) { bilans.first }
    context 'having results' do
      let(:bilans) { JSON.parse(File.read('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf_with_bilans.json'))["data"] }

      it 'find value' do
        expect(extract_resultat_exercice(bilan["data"])).to eq("97065000")
      end
    end

    context 'without results' do
      let(:bilans) { JSON.parse(File.read('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf.json'))["data"] }

      it 'does not crash' do
        expect(extract_resultat_exercice(bilan["data"])).to eq(nil)
      end
    end
  end

  describe '#raison_sociale_or_name' do
    subject { raison_sociale_or_name(etablissement) }

    context 'when etablissement is not the siege and enseigne exist' do
      let(:enseigne) { "mon enseigne" }
      it 'display enseigne and localité' do
        expect(subject).to eq("mon enseigne - BOIS COLOMBES")
      end
    end

    context 'when raison_sociale exist' do
      let(:raison_sociale) { 'ma super raison_sociale' }
      let(:enseigne) { nil }
      it 'display raison_sociale' do
        expect(subject).to eq(raison_sociale)
      end
    end

    context 'when raison_sociale is nil' do
      let(:raison_sociale) { nil }
      let(:enseigne) { nil }
      it 'display nom and prenom' do
        expect(subject).to eq("#{nom} #{prenom}")
      end
    end
  end

  describe '#effectif' do
    subject { effectif(etablissement) }

    context 'when code_effectif is 00' do
      let(:code_effectif) { '01' }
      it { is_expected.to eq('1 ou 2 salariés') }
    end

    context 'when code_effectif is 32' do
      let(:code_effectif) { '32' }
      it { is_expected.to eq('250 à 499 salariés') }
    end
  end

  describe '#pretty_currency' do
    subject { pretty_currency(etablissement.entreprise_capital_social) }

    it { is_expected.to eq('123 000 €') }
  end

  describe '#pretty_currency with special unit' do
    subject { pretty_currency(12345, unit: 'k€') }

    it { is_expected.to eq('12 345 k€') }
  end
  describe '#pretty_date_exercice' do
    subject { pretty_date_exercice("201908") }
    it { is_expected.to eq("2019") }
  end

  describe "#humanized_entreprise_etat_administratif" do
    subject { humanized_entreprise_etat_administratif(etablissement) }

    context "when etat_administratif is A" do
      let(:etat_administratif) { "actif" }
      it { is_expected.to eq("en activité") }
    end

    context "when etat_administratif is F" do
      let(:etat_administratif) { "fermé" }
      it { is_expected.to eq("fermé") }
    end

    context "when etat_administratif is nil" do
      let(:etat_administratif) { nil }
      it { is_expected.to be_nil }
    end
  end
end
