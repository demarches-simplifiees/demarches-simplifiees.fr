RSpec.describe Dossiers::EditFooterComponent, type: :component do
  let(:annotation) { false }
  let(:component) { Dossiers::EditFooterComponent.new(dossier:, annotation:) }

  subject { render_inline(component).to_html }

  before { allow(component).to receive(:owner?).and_return(true) }

  context 'when brouillon' do
    let(:dossier) { create(:dossier, :brouillon) }

    context 'when dossier can be submitted' do
      before { allow(component).to receive(:can_passer_en_construction?).and_return(true) }
      it 'renders submit button without disabled' do
        expect(subject).to have_selector('button', text: 'Déposer le dossier')
      end
    end

    context 'when dossier can not be submitted' do
      before { allow(component).to receive(:can_passer_en_construction?).and_return(false) }
      it 'renders submit button with disabled' do
        expect(subject).to have_selector('a', text: 'Pourquoi je ne peux pas déposer mon dossier ?')
        expect(subject).to have_selector('button[disabled]', text: 'Déposer le dossier')
      end
    end
  end

  context 'when en construction' do
    let(:fork_origin) { create(:dossier, :en_construction) }
    let(:dossier) { fork_origin.clone(fork: true) }
    before { allow(dossier).to receive(:forked_with_changes?).and_return(true) }

    context 'when dossier can be submitted' do
      before { allow(component).to receive(:can_passer_en_construction?).and_return(true) }

      it 'renders submit button without disabled' do
        expect(subject).to have_selector('button', text: 'Déposer les modifications')
      end
    end

    context 'when dossier can not be submitted' do
      before { allow(component).to receive(:can_passer_en_construction?).and_return(false) }

      it 'renders submit button with disabled' do
        expect(subject).to have_selector('a', text: 'Pourquoi je ne peux pas déposer mon dossier ?')
        expect(subject).to have_selector('button[disabled]', text: 'Déposer les modifications')
      end
    end
  end
end
