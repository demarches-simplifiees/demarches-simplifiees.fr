require 'spec_helper'

describe 'new_user/dossiers/show.html.haml', type: :view do
  let(:dossier) { create(:dossier, :en_construction, procedure: create(:procedure)) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'renders a summary of the dossier state' do
    expect(rendered).to have_text("Dossier nº #{dossier.id}")
    expect(rendered).to have_selector('.status-overview')
  end
end
