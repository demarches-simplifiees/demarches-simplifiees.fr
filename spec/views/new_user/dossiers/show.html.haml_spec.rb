require 'spec_helper'

describe 'new_user/dossiers/show.html.haml', type: :view do
  let(:dossier) { create(:dossier, :en_construction) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'renders a summary of the dossier state' do
    expect(rendered).to have_text("Dossier nº #{dossier.id}")
    expect(rendered).to have_selector('.status-overview')
  end

  context 'with messages' do
    let(:first_message) { create(:commentaire, body: 'Premier message') }
    let(:last_message)  { create(:commentaire, body: 'Second message') }
    let(:dossier) { create(:dossier, :en_construction, commentaires: [first_message, last_message]) }

    it 'displays the last message' do
      expect(rendered).not_to have_text(first_message.body)
      expect(rendered).to have_text(last_message.body)
    end
  end
end
