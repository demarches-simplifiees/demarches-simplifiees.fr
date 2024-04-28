# frozen_string_literal: true

describe 'users/dossiers/papertrail', type: :view do
  before do
    assign(:dossier, dossier)
  end

  subject { render }

  context 'for a dossier with an individual' do
    let(:dossier) { create(:dossier, :en_construction, :with_service, :with_individual) }

    it 'renders a PDF document with the dossier state' do
      subject
      expect(rendered).to be_present
    end
  end

  context 'for a dossier with a SIRET' do
    let(:dossier) { create(:dossier, :en_construction, :with_service, :with_entreprise) }

    it 'renders a PDF document with the dossier state' do
      subject
      expect(rendered).to be_present
    end
  end
end
