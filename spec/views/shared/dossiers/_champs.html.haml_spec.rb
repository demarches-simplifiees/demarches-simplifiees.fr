describe 'shared/dossiers/champs', type: :view do
  let(:instructeur) { create(:instructeur) }
  let(:demande_seen_at) { nil }
  let(:profile) { "instructeur" }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:types_de_champ) { dossier.revision.types_de_champ_public }

  before do
    view.extend DossierHelper
    view.extend DossierLinkHelper

    if profile == "instructeur"
      allow(view).to receive(:current_instructeur).and_return(instructeur)
    end
  end

  subject { render ViewableChamp::SectionComponent.new(types_de_champ:, dossier:, demande_seen_at:, profile:) }

  context "there are some champs" do
    let(:types_de_champ_public) { [{ type: :checkbox }, { type: :header_section }, { type: :explication }, { type: :dossier_link }, { type: :textarea }, { type: :rna }] }
    let(:champ1) { dossier.champs[0] }
    let(:champ2) { dossier.champs[1] }
    let(:champ3) { dossier.champs[2] }
    let(:champ4) { dossier.champs[3] }
    let(:champ5) { dossier.champs[4] }
    let(:champ6) { dossier.champs[5] }

    before do
      champ1.update(value: 'true')
      champ4.update(value: dossier.id)
      champ5.update(value: "Some long text in a textarea.")
      champ6.update(value: "W173847273")
    end

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
    end
  end

  context "with auto-link" do
    let(:types_de_champ_public) { [{ type: :text }, { type: :textarea }] }
    let(:champ1) { dossier.champs[0] }
    let(:champ2) { dossier.champs[1] }

    before do
      champ1.update(value: 'https://github.com/tchak')
      champ2.update(value: "https://github.com/LeSim")
    end

    let(:link1) { '<a href="https://github.com/tchak" target="_blank" rel="noopener">https://github.com/tchak</a>' }
    let(:link2) { '<a href="https://github.com/LeSim" target="_blank" rel="noopener">https://github.com/LeSim</a>' }

    it "render links" do
      expect(subject).to include(link1)
      expect(subject).to include(link2)
    end
  end

  context "with a dossier champ, but we are not authorized to acces the dossier" do
    let(:types_de_champ_public) { [{ type: :dossier_link }] }

    before do
      dossier.champs.first.update(value: dossier.id)
    end

    it { is_expected.not_to have_link("Dossier nº #{dossier.id}") }
    it { is_expected.to include("Dossier nº #{dossier.id}") }
    it { is_expected.to include(dossier.text_summary) }
  end

  context "with a dossier_link champ but without value" do
    let(:types_de_champ_public) { [{ type: :dossier_link }] }

    before do
      dossier.champs.first.update(value: nil)
    end

    it { is_expected.not_to include("non saisi") }

    context 'when profile is usager' do
      let(:profile) { "usager" }
      it { is_expected.to include("non saisi (facultatif)") }
    end
  end

  context "with a piece justificative without value" do
    let(:types_de_champ_public) { [{ type: :piece_justificative }] }

    before do
      dossier.champs.first.piece_justificative_file.purge
    end

    it { is_expected.not_to include("pièce justificative non saisie") }

    context 'when profile is usager' do
      let(:profile) { "usager" }
      it { is_expected.to include("pièce justificative non saisie (facultative)") }
    end
  end

  context "with seen_at" do
    let(:types_de_champ_public) { [{ type: :checkbox }] }
    let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure:, depose_at: 1.day.ago) }
    let(:champ1) { dossier.champs[0] }

    context "with a demande_seen_at after champ updated_at" do
      let(:demande_seen_at) { champ1.updated_at + 1.hour }

      it { is_expected.not_to have_css(".fr-badge--new") }
    end

    context "with champ updated_at at depose_at" do
      let(:champ1) { dossier.champs[0] }
      let(:demande_seen_at) { champ1.updated_at - 1.hour }

      before do
        champ1.update(value: 'false', updated_at: dossier.depose_at)
      end

      it { is_expected.not_to have_css(".fr-badge--new") }
    end

    context "with a demande_seen_at after champ updated_at" do
      let(:demande_seen_at) { champ1.updated_at - 1.hour }

      it { is_expected.to have_css(".fr-badge--new") }
    end
  end
end
