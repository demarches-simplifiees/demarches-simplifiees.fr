# frozen_string_literal: true

describe 'layouts/procedure_context', type: :view do
  let(:procedure) { create(:simple_procedure, :with_service) }
  let(:dossier) { create(:dossier, procedure: procedure) }

  before do
    allow(view).to receive(:instructeur_signed_in?).and_return(false)
    allow(view).to receive(:administrateur_signed_in?).and_return(false)
    allow(view).to receive(:localization_enabled?).and_return(false)
    allow(view).to receive(:extra_query_params).and_return({})
  end

  subject do
    render html: 'Column content', layout: 'layouts/procedure_context'
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
end
