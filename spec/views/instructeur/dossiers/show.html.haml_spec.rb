describe 'instructeurs/dossiers/show.html.haml', type: :view do
  let(:current_instructeur) { create(:instructeur) }
  let(:dossier) { create(:dossier, :en_construction) }

  before do
    sign_in current_instructeur
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'renders the header' do
    expect(rendered).to have_text("Dossier nº #{dossier.id}")
  end

  it 'renders the dossier infos' do
    expect(rendered).to have_text('Identité')
    expect(rendered).to have_text('Demande')
  end
end
