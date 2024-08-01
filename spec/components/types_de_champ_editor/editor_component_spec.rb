# frozen_string_literal: true

describe TypesDeChampEditor::EditorComponent, type: :component do
  let(:revision) { procedure.draft_revision }
  let(:procedure) { create(:procedure, id: 1, types_de_champ_private:, types_de_champ_public:) }

  let(:types_de_champ_private) { [{ type: :drop_down_list, options: [], libelle: 'private' }] }
  let(:types_de_champ_public) { [{ type: :drop_down_list, options: [], libelle: 'public' }] }

  describe 'render' do
    subject { render_inline(described_class.new(revision:, is_annotation:)) }
    context 'types_de_champ_public' do
      let(:is_annotation) { false }
      it 'does not render private champs errors' do
        expect(subject).not_to have_text("private")
        expect(subject).to have_selector("a", text: "public")
        expect(subject).to have_text("doit comporter au moins un choix sélectionnable")
      end
    end

    context 'types_de_champ_private' do
      let(:is_annotation) { true }
      it 'does not render public champs errors' do
        expect(subject).to have_selector("a", text: "private")
        expect(subject).to have_text("doit comporter au moins un choix sélectionnable")
        expect(subject).not_to have_text("public")
      end
    end
  end
end
