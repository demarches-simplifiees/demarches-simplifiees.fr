describe 'shared/dossiers/champs', type: :view do
  let(:instructeur) { create(:instructeur) }
  let(:demande_seen_at) { nil }
  let(:profile) { "instructeur" }

  before do
    view.extend DossierHelper
    view.extend DossierLinkHelper

    if profile == "instructeur"
      allow(view).to receive(:current_instructeur).and_return(instructeur)
    end
  end

  subject { render 'shared/dossiers/champs', champs:, dossier:, demande_seen_at:, profile: }

  context "there are some champs" do
    let(:dossier) { create(:dossier) }
    let(:champ1) { create(:champ_checkbox, dossier: dossier, value: 'true') }
    let(:champ2) { create(:champ_header_section, dossier: dossier, value: "Section") }
    let(:champ3) { create(:champ_explication, dossier: dossier, value: "mazette") }
    let(:champ4) { create(:champ_dossier_link, dossier: dossier, value: dossier.id) }
    let(:champ5) { create(:champ_textarea, dossier: dossier, value: "Some long text in a textarea.") }
    let(:champ6) { create(:champ_rna, value: "W173847273") }
    let(:champs) { [champ1, champ2, champ3, champ4, champ5, champ6] }

    it "renders titles and values of champs" do
      expect(subject).to include(champ1.libelle)
      expect(subject).to include('Oui')

      expect(subject).to have_css(".header-section")
      expect(subject).to include(champ2.libelle)

      expect(subject).to include(dossier.text_summary)

      expect(subject).to include(champ5.libelle)
      expect(subject).to include(champ5.value)
      expect(subject).to include(champ6.libelle)
      expect(subject).to include(champ6.value)
    end

    it "doesn't render explication champs" do
      expect(subject).not_to include(champ3.libelle)
      expect(subject).not_to include(champ3.value)
    end

    context "with auto-link" do
      let(:champ1) { create(:champ_text, value: "https://github.com/tchak") }
      let(:champ2) { create(:champ_textarea, value: "https://github.com/LeSim") }
      let(:link1) { '<a href="https://github.com/tchak" target="_blank" rel="noopener">https://github.com/tchak</a>' }
      let(:link2) { '<a href="https://github.com/LeSim" target="_blank" rel="noopener">https://github.com/LeSim</a>' }

      it "render links" do
        expect(subject).to include(link1)
        expect(subject).to include(link2)
      end
    end
  end

  context "with a routed procedure" do
    let(:procedure) do
      create(:procedure, :routee)
    end
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let(:champs) { [] }

    context "with seen_at" do
      let(:dossier) { create(:dossier) }
      let(:nouveau_groupe_instructeur) { create(:groupe_instructeur, procedure: dossier.procedure) }
      let(:champ1) { create(:champ_checkbox, dossier: dossier, value: 'true') }
      let(:champs) { [champ1] }

      context "with a demande_seen_at after groupe_instructeur_updated_at" do
        let(:demande_seen_at) { dossier.groupe_instructeur_updated_at + 1.hour }

        it "expect to not highlight new group instructeur label" do
          dossier.assign_to_groupe_instructeur(nouveau_groupe_instructeur)
          expect(subject).not_to have_css(".highlighted")
        end
      end

      context "with a demande_seen_at before groupe_instructeur_updated_at" do
        let(:demande_seen_at) { dossier.groupe_instructeur_updated_at - 1.hour }

        it "expect to not highlight new group instructeur label" do
          dossier.assign_to_groupe_instructeur(nouveau_groupe_instructeur)
          expect(subject).to have_css(".highlighted")
        end
      end
    end
  end

  context "with a dossier champ, but we are not authorized to acces the dossier" do
    let(:dossier) { create(:dossier) }
    let(:champ) { create(:champ_dossier_link, dossier: dossier, value: dossier.id) }
    let(:champs) { [champ] }

    it { is_expected.not_to have_link("Dossier nº #{dossier.id}") }
    it { is_expected.to include("Dossier nº #{dossier.id}") }
    it { is_expected.to include(dossier.text_summary) }
  end

  context "with a dossier_link champ but without value" do
    let(:dossier) { create(:dossier) }
    let(:champ) { create(:champ_dossier_link, dossier: dossier, value: nil) }
    let(:champs) { [champ] }

    it { is_expected.not_to include("non saisi") }

    context 'when profile is usager' do
      let(:profile) { "usager" }
      it { is_expected.to include("non saisi (facultatif)") }
    end
  end

  context "with a piece justificative without value" do
    let(:dossier) { create(:dossier) }
    let(:champ) { create(:champ_without_piece_justificative, dossier:) }
    let(:champs) { [champ] }

    it { is_expected.not_to include("pièce justificative non saisie") }

    context 'when profile is usager' do
      let(:profile) { "usager" }
      it { is_expected.to include("pièce justificative non saisie (facultative)") }
    end
  end

  context "with seen_at" do
    let(:dossier) { create(:dossier, :en_construction, depose_at: 1.day.ago) }
    let(:champ1) { create(:champ_checkbox, dossier: dossier, value: 'true') }
    let(:champs) { [champ1] }

    context "with a demande_seen_at after champ updated_at" do
      let(:demande_seen_at) { champ1.updated_at + 1.hour }

      it { is_expected.not_to have_css(".fr-badge--new") }
    end

    context "with champ updated_at at depose_at" do
      let(:champ1) { create(:champ_checkbox, dossier: dossier, value: 'true', updated_at: dossier.depose_at) }
      let(:demande_seen_at) { champ1.updated_at - 1.hour }

      it { is_expected.not_to have_css(".fr-badge--new") }
    end

    context "with a demande_seen_at after champ updated_at" do
      let(:demande_seen_at) { champ1.updated_at - 1.hour }

      it { is_expected.to have_css(".fr-badge--new") }
    end
  end
end
