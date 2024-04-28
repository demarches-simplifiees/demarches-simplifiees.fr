# frozen_string_literal: true

describe 'dossiers/dossier_vide', type: :view do
  let(:procedure) { create(:procedure, :with_all_champs) }

  before do
    assign(:procedure, procedure)
    assign(:revision, procedure.draft_revision)
  end

  subject { render }

  it 'renders a PDF document with empty fields' do
    subject
    expect(rendered).to be_present
  end
end
