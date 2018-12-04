describe 'new_user/dossiers/show/header.html.haml', type: :view do
  let(:dossier) { create(:dossier, :en_construction, procedure: create(:procedure)) }

  before do
    sign_in dossier.user
  end

  subject! { render 'new_user/dossiers/show/header.html.haml', dossier: dossier }

  it 'affiche les informations du dossier' do
    expect(rendered).to have_text(dossier.procedure.libelle)
    expect(rendered).to have_text("Dossier nº #{dossier.id}")
    expect(rendered).to have_text("en construction")

    expect(rendered).to have_selector("ul.tabs")
    expect(rendered).to have_link("Résumé", href: dossier_path(dossier))
    expect(rendered).to have_link("Demande", href: demande_dossier_path(dossier))
  end
end
