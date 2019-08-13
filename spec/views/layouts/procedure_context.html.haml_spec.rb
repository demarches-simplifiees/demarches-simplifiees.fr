require 'rails_helper'

describe 'layouts/procedure_context.html.haml', type: :view do
  let(:procedure) { create(:simple_procedure, :with_service) }
  let(:dossier) { create(:dossier, procedure: procedure) }

  before do
    allow(view).to receive(:instructeur_signed_in?).and_return(false)
  end

  subject do
    render html: 'Column content', layout: 'layouts/procedure_context.html.haml'
  end

  context 'when a procedure is assigned' do
    before do
      assign(:procedure, procedure)
    end

    it 'renders a description of the procedure' do
      expect(subject).to have_text(procedure.libelle)
      expect(subject).to have_text(procedure.description)
    end

    it 'renders the inner content' do
      expect(subject).to have_text('Column content')
    end

    it 'renders the procedure footer' do
      expect(subject).to have_text(procedure.service.nom)
      expect(subject).to have_text(procedure.service.email)
    end
  end

  context 'when a dossier is assigned' do
    before do
      assign(:dossier, dossier)
    end

    it 'renders a description of the procedure' do
      expect(subject).to have_text(dossier.procedure.libelle)
      expect(subject).to have_text(dossier.procedure.description)
    end

    it 'renders the inner content' do
      expect(subject).to have_text('Column content')
    end

    it 'renders the procedure footer' do
      expect(subject).to have_text(dossier.procedure.service.nom)
      expect(subject).to have_text(dossier.procedure.service.email)
    end
  end

  context 'when neither procedure or dossier are assigned' do
    it 'renders a placeholder for the procedure' do
      expect(subject).to have_selector('.no-procedure')
    end

    it 'renders the inner content' do
      expect(subject).to have_text('Column content')
    end

    it 'renders a generic footer' do
      expect(subject).to have_text('Mentions légales')
    end
  end
end
