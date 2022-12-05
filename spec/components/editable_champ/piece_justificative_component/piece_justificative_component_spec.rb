describe EditableChamp::PieceJustificativeComponent, type: :component do
  let(:champ) { create(:champ_piece_justificative, dossier: create(:dossier)) }
  let(:component) {
    described_class.new(form: instance_double(ActionView::Helpers::FormBuilder, object_name: "dossier[champs_public_attributes]"), champ:)
  }

  let(:subject) {
    render_inline(component).to_html
  }

  context 'when there is a template' do
    let(:template) { champ.type_de_champ.piece_justificative_template }
    let(:profil) { :user }

    before do
      allow_any_instance_of(ApplicationController).to receive(:administrateur_signed_in?).and_return(profil == :administrateur)
    end

    it 'renders a link to template' do
      expect(subject).to have_link('Modèle à télécharger')
      expect(subject).not_to have_text("éphémère")
    end

    context 'as an administrator' do
      let(:profil) { :administrateur }
      it 'warn about ephemeral template url' do
        expect(subject).to have_link('Modèle à télécharger')
        expect(subject).to have_text("éphémère")
      end
    end
  end
end
