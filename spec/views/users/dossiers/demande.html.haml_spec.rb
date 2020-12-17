describe 'users/dossiers/demande.html.haml', type: :view do
  let(:procedure) { create(:procedure, :published, :with_type_de_champ, :with_type_de_champ_private) }
  let(:dossier) { create(:dossier, :en_construction, :with_entreprise, procedure: procedure) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'renders the header' do
    expect(rendered).to have_text("Dossier nº #{dossier.id}")
  end

  it 'renders the dossier infos' do
    expect(rendered).to have_text('Déposé le')
    expect(rendered).to have_text('Identité')
    expect(rendered).to have_text('Demande')
  end

  context 'when the dossier is editable' do
    it { is_expected.to have_link('Modifier le dossier', href: modifier_dossier_path(dossier)) }
  end

  context 'when the dossier is read-only' do
    let(:dossier) { create(:dossier, :en_instruction, :with_entreprise, procedure: procedure) }
    it { is_expected.not_to have_link('Modifier le dossier') }
  end

  context 'when the dossier has no en_construction_at date' do
    let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure) }

    it { expect(rendered).not_to have_text('Déposé le') }
  end

  context 'when the user is logged in with france connect' do
    let(:france_connect_information) { build(:france_connect_information) }
    let(:loged_in_with_france_connect) { User.loged_in_with_france_connects.fetch(:particulier) }
    let(:user) { build(:user, france_connect_information: france_connect_information, loged_in_with_france_connect: loged_in_with_france_connect) }
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
