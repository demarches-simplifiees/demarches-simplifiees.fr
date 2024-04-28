# frozen_string_literal: true

describe Procedure::ErrorsSummary, type: :component do
  subject { render_inline(described_class.new(procedure:, validation_context:)) }

  describe 'validations context' do
    let(:procedure) { create(:procedure, types_de_champ_private:, types_de_champ_public:) }
    let(:types_de_champ_private) { [{ type: :drop_down_list, options: [], libelle: 'private' }] }
    let(:types_de_champ_public) { [{ type: :drop_down_list, options: [], libelle: 'public' }] }

    before { subject }

    context 'when :publication' do
      let(:validation_context) { :publication }

      it 'shows errors and links for public and private tdc' do
        expect(page).to have_content("Erreur : Des problèmes empêchent la publication de la démarche")
        expect(page).to have_selector("a", text: "public")
        expect(page).to have_selector("a", text: "private")
        expect(page).to have_text("doit comporter au moins un choix sélectionnable", count: 2)
      end
    end

    context 'when :types_de_champ_public_editor' do
      let(:validation_context) { :types_de_champ_public_editor }

      it 'shows errors and links for public only tdc' do
        expect(page).to have_text("Erreur : Les champs formulaire contiennent des erreurs")
        expect(page).to have_selector("a", text: "public")
        expect(page).to have_text("doit comporter au moins un choix sélectionnable", count: 1)
        expect(page).not_to have_selector("a", text: "private")
      end
    end

    context 'when :types_de_champ_private_editor' do
      let(:validation_context) { :types_de_champ_private_editor }

      it 'shows errors and links for private only tdc' do
        expect(page).to have_text("Erreur : Les annotations privées contiennent des erreurs")
        expect(page).to have_selector("a", text: "private")
        expect(page).to have_text("doit comporter au moins un choix sélectionnable")
        expect(page).not_to have_selector("a", text: "public")
      end
    end
  end

  describe 'render all kind of champs errors' do
    include Logic

    let(:procedure) do
      create(:procedure, id: 1, types_de_champ_public: [
        { libelle: 'repetition requires children', type: :repetition, children: [] },
        { libelle: 'drop down list requires options', type: :drop_down_list, options: [] },
        { libelle: 'invalid condition', type: :text, condition: ds_eq(constant(true), constant(1)) },
        { libelle: 'header sections must have consistent order', type: :header_section, level: 2 },
        { libelle: 'regexp invalid', type: :expression_reguliere, expression_reguliere_exemple_text: 'kthxbye', expression_reguliere: /{/ }
      ])
    end

    let(:validation_context) { :types_de_champ_public_editor }

    before { subject }

    it 'renders all errors  and links on champ' do
      expect(page).to have_selector("a", text: "drop down list requires options")
      expect(page).to have_content("doit comporter au moins un choix sélectionnable")

      expect(page).to have_selector("a", text: "repetition requires children")
      expect(page).to have_content("doit comporter au moins un champ répétable")

      expect(page).to have_selector("a", text: "invalid condition")
      expect(page).to have_content("a une logique conditionnelle invalide")

      expect(page).to have_selector("a", text: "header sections must have consistent order")
      expect(page).to have_content("devrait être précédé d'un titre de niveau 1")

      expect(page).to have_selector("a", text: "regexp invalid")
      expect(page).to have_content("est invalide, veuillez la corriger")
    end
  end

  describe 'render error for other kind of associated objects' do
    include Logic

    let(:validation_context) { :publication }
    let(:procedure) { create(:procedure, attestation_template:, initiated_mail:) }
    let(:attestation_template) { build(:attestation_template) }
    let(:initiated_mail) { build(:initiated_mail) }

    before do
      [:attestation_template, :initiated_mail].map { procedure.send(_1).update_column(:body, '--invalidtag--') }
      procedure.draft_revision.update(ineligibilite_enabled: true, ineligibilite_rules: ds_eq(constant(true), constant(1)), ineligibilite_message: 'ko')
      subject
    end

    it 'render error nicely' do
      expect(page).to have_selector("a", text: "Les règles d’inéligibilité")
      expect(page).to have_selector("a", text: "Le modèle d’attestation")
      expect(page).to have_selector("a", text: "L’email de notification de passage de dossier en instruction")
      expect(page).to have_text("n'est pas valide", count: 2)
    end
  end
end
