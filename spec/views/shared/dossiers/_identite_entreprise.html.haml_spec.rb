# frozen_string_literal: true

describe 'shared/dossiers/identite_entreprise', type: :view do
  subject { render 'shared/dossiers/identite_entreprise', etablissement: etablissement, profile: profile }
  let(:profile) { 'usager' }

  context "there is an association" do
    let(:etablissement) { create(:etablissement, :is_association) }

    context "date_publication is missing on rna" do
      before { etablissement.update(association_date_publication: nil) }

      it "can render without error" do
        subject
        expect(rendered).to include("Date de publication :")
      end
    end
  end

  context "for an entreprise with private infos" do
    let(:etablissement) { create(:etablissement, :non_diffusable, siret: "12345678900001") }

    it "hide any info except siret" do
      subject
      expect(rendered).to have_text("123 456 789 00001")
      expect(rendered).not_to have_text(etablissement.entreprise_raison_sociale)
      expect(rendered).not_to have_text(etablissement.entreprise.forme_juridique)
    end
  end

  context 'for instructeur' do
    let(:profile) { 'instructeur' }

    context 'with bilans bdf v2' do
      let(:bilans) { JSON.parse(File.read('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf_v2.json')) }
      let(:bilans_array) { bilans["bilans"] }
      let(:bilans_monnaie) { bilans["monnaie"] }
      let(:etablissement) { create(:etablissement, entreprise_bilans_bdf: bilans_array, entreprise_bilans_bdf_monnaie: bilans_monnaie, dossier: create(:dossier)) }

      it "can render without error" do
        assign(:dossier, etablissement.dossier)
        subject
        expect(rendered).to include("Excédent brut d’exploitation")
        expect(rendered).to include("-1 876 863 k€")
      end
    end

    context 'with bilans bdf v3' do
      let(:bilans) { JSON.parse(File.read('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf.json')) }
      let(:bilans_array) { bilans["data"] }
      let(:bilans_monnaie) { "euros" }
      let(:etablissement) { create(:etablissement, entreprise_bilans_bdf: bilans_array, entreprise_bilans_bdf_monnaie: bilans_monnaie, dossier: create(:dossier)) }

      it "can render without error" do
        assign(:dossier, etablissement.dossier)
        subject
        expect(rendered).to include("Excédent brut d’exploitation")
        expect(rendered).to include("9 001")
      end
    end

    context 'siret siege social' do
      let(:etablissement) { create(:etablissement, siret: "12345678900001", entreprise_siret_siege_social: siret_siege_social) }

      context 'when siege social has same siret' do
        let(:siret_siege_social) { "12345678900001" }

        it 'does not duplicate siret' do
          expect(subject).to include("123 456 789 00001").once
        end
      end

      context 'when siege social is different' do
        let(:siret_siege_social) { "98765432100001" }

        it 'shows both sirets' do
          expect(subject).to include("123 456 789 00001")
          expect(subject).to include("Numéro TAHITI du siège social")
          expect(subject).to include("987 654 321 00001")
        end
      end

      context 'when siege social has no siret' do
        let(:siret_siege_social) { nil }

        it 'does not duplicate siret' do
          expect(subject).not_to include("Numéro TAHITI du siège social")
        end
      end
    end
  end
end
