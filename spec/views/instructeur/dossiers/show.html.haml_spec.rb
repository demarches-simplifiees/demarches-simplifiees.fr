describe 'instructeurs/dossiers/show.html.haml', type: :view do
  let(:current_instructeur) { create(:instructeur) }
  let(:dossier) { create(:dossier, :en_construction) }

  before do
    sign_in(current_instructeur.user)
    allow(view).to receive(:current_instructeur).and_return(current_instructeur)
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

  context 'when the user is logged in with france connect' do
    let(:france_connect_information) { build(:france_connect_information) }
    let(:user) { build(:user, france_connect_information: france_connect_information, loged_in_with_france_connect: 'particulier') }
    let(:procedure1) { create(:procedure, :with_type_de_champ, for_individual: true) }
    let(:dossier) { create(:dossier, procedure: procedure1, user: user) }

    before do
      render
    end

    it 'fills the individual with the informations from France Connect' do
      expect(rendered).to have_text("Le dossier a été déposé par le compte de #{france_connect_information.given_name} #{france_connect_information.family_name}, authentifié par France Connect le #{france_connect_information.updated_at.strftime('%d/%m/%Y')}")
    end
  end
end
