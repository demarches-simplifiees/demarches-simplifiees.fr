describe Procedure::ErrorsSummary, type: :component do
  subject { render_inline(described_class.new(procedure:, validation_context:)) }

  describe 'validations context' do
    let(:procedure) { create(:procedure, types_de_champ_private:, types_de_champ_public:) }
    let(:types_de_champ_private) { [{ type: :drop_down_list, options: [], libelle: 'private' }] }
    let(:types_de_champ_public) { [{ type: :drop_down_list, options: [], libelle: 'public' }] }

    before { subject }

    context 'when :publication' do
      let(:validation_context) { :publication }

      it 'shows errors for public and private tdc' do
        expect(page).to have_text("Le champ « public » doit comporter au moins un choix sélectionnable")
        expect(page).to have_text("L’annotation privée « private » doit comporter au moins un choix sélectionnable")
      end
    end

    context 'when :types_de_champ_public_editor' do
      let(:validation_context) { :types_de_champ_public_editor }

      it 'shows errors for public only tdc' do
        expect(page).to have_text("Le champ « public » doit comporter au moins un choix sélectionnable")
        expect(page).not_to have_text("L’annotation privée « private » doit comporter au moins un choix sélectionnable")
      end
    end

    context 'when :types_de_champ_private_editor' do
      let(:validation_context) { :types_de_champ_private_editor }

      it 'shows errors for private only tdc' do
        expect(page).not_to have_text("Le champ « public » doit comporter au moins un choix sélectionnable")
        expect(page).to have_text("L’annotation privée « private » doit comporter au moins un choix sélectionnable")
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
        { libelle: 'header sections must have consistent order', type: :header_section, level: 2 }
      ])
    end

    let(:validation_context) { :types_de_champ_public_editor }

    before { subject }

    it 'renders all errors on champ' do
      expect(page).to have_text("Le champ « drop down list requires options » doit comporter au moins un choix sélectionnable")
      expect(page).to have_text("Le champ « repetition requires children » doit comporter au moins un champ répétable")
      expect(page).to have_text("Le champ « invalid condition » a une logique conditionnelle invalide")
      expect(page).to have_text("Le champ « header sections must have consistent order » devrait être précédé d'un titre de niveau 1")
      # TODO, test attestation_template, initiated_mail, :received_mail, :closed_mail, :refused_mail, :without_continuation_mail, :re_instructed_mail
    end
  end

  describe 'render error for other kind of associated objects' do
    let(:validation_context) { :publication }
    let(:procedure) { create(:procedure, attestation_template:, initiated_mail:) }
    let(:attestation_template) { build(:attestation_template) }
    let(:initiated_mail) { build(:initiated_mail) }

    before do
      [:attestation_template, :initiated_mail].map { procedure.send(_1).update_column(:body, '--invalidtag--') }
      subject
    end

    it 'render error nicely' do
      expect(page).to have_text("Le modèle d’attestation n'est pas valide")
      expect(page).to have_text("L’email de notification de passage de dossier en instruction n'est pas valide")
    end
  end
end
