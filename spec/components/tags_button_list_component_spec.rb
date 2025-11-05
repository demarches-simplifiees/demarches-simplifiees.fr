# frozen_string_literal: true

RSpec.describe TagsButtonListComponent, type: :component do
  let(:tags) do
    {
      individual: TagsSubstitutionConcern::INDIVIDUAL_TAGS,
      etablissement: TagsSubstitutionConcern::ENTREPRISE_TAGS,
      dossier: TagsSubstitutionConcern::DOSSIER_TAGS,
      champ_public: [
        {
          id: 'tdc12',
          libelle: 'Votre avis',
          description: 'Détaillez votre avis',
        },
        {
          id: 'tdc13',
          libelle: 'Un champ avec un nom très ' + 'long ' * 12,
          description: 'Ce libellé a été tronqué',
          maybe_null:,
        },
      ],

      champ_private: [
        {
          id: 'tdc22',
          libelle: 'Montant accordé',
        },
      ],
    }
  end
  let(:maybe_null) { true }

  let(:component) do
    described_class.new(tags:)
  end

  subject { render_inline(component).to_html }

  it 'renders' do
    expect(subject).to have_text("Identité")
    expect(subject).to have_text("civilité")
    expect(subject).to have_text("Votre avis")
    expect(subject).to have_text("Montant accordé")
  end

  it "hide nullable tag" do
    expect(subject).to have_selector(".hidden button.fr-tag", text: "Un champ avec un nom")
    expect(subject).to have_selector(":not(.hidden) button.fr-tag", text: "Votre avis")
    expect(subject).to have_text("Voir les champs facultatifs")
  end

  context "all champs are visible" do
    let(:maybe_null) { false }
    it {
      expect(subject).not_to have_text("Voir les champs facultatifs")
    }
  end
end
