# frozen_string_literal: true

describe 'instructeurs/procedures/show', type: :view do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, instructeurs: [instructeur], libelle: 'abc') }
  subject { render }

  before do
    assign(:counts, {})
    assign(:current_filters, [])
    assign(:procedure, procedure)
    allow(view).to receive(:current_administrateur).and_return(nil)
    allow(view).to receive(:current_instructeur).and_return(instructeur)
  end

  context 'with procedure having procedure_expires_when_termine_enabled not enabled' do
    it 'renders breadcrumb' do
      expect(subject).to have_selector(".fr-breadcrumb__link", count: 2)
      expect(subject).to have_selector("a.fr-breadcrumb__link", text: "Accueil – Liste des démarches")
      expect(subject).to have_selector('a.fr-breadcrumb__link', text: procedure.libelle)
    end
  end
end
