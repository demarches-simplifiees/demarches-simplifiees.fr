describe 'users/dossiers/index.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:dossier_brouillon) { create(:dossier, state: Dossier.states.fetch(:brouillon), user: user) }
  let(:dossier_en_construction) { create(:dossier, state: Dossier.states.fetch(:en_construction), user: user) }
  let(:user_dossiers) { [dossier_brouillon, dossier_en_construction] }
  let(:dossiers_invites) { [] }
  let(:statut) { 'mes-dossiers' }

  before do
    allow(view).to receive(:new_demarche_url).and_return('#')
    allow(controller).to receive(:current_user) { user }
    assign(:user_dossiers, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossiers_invites, Kaminari.paginate_array(dossiers_invites).page(1))
    assign(:dossiers_supprimes, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:statut, statut)
    render
  end

  it 'affiche la liste des dossiers' do
    expect(rendered).to have_selector('.dossiers-table tbody tr', count: 2)
  end

  it 'affiche les informations des dossiers' do
    dossier = user_dossiers.first
    expect(rendered).to have_text(dossier_brouillon.id.to_s)
    expect(rendered).to have_text(dossier_brouillon.procedure.libelle)
    expect(rendered).to have_link(dossier_brouillon.id.to_s, href: brouillon_dossier_path(dossier_brouillon))

    expect(rendered).to have_text(dossier_en_construction.id.to_s)
    expect(rendered).to have_text(dossier_en_construction.procedure.libelle)
    expect(rendered).to have_link(dossier_en_construction.id.to_s, href: dossier_path(dossier_en_construction))
  end

  context 'quand il n’y a aucun dossier' do
    let(:user_dossiers)    { [] }
    let(:dossiers_invites) { [] }

    it 'n’affiche pas la table' do
      expect(rendered).not_to have_selector('.dossiers-table')
    end

    it 'affiche un message' do
      expect(rendered).to have_text('Aucun dossier')
    end
  end

  context 'quand il n’y a pas de dossiers invités' do
    let(:dossiers_invites) { [] }

    it 'affiche un titre adapté' do
      expect(rendered).to have_selector('h1', text: 'Dossiers')
    end

    it 'n’affiche la barre d’onglets' do
      expect(rendered).to have_selector('ul.tabs')
    end
  end

  context 'quand il y a des dossiers invités' do
    let(:dossiers_invites) { create_list(:dossier, 1) }

    it 'affiche un titre adapté' do
      expect(rendered).to have_selector('h1', text: 'Dossiers')
    end

    it 'affiche la barre d’onglets' do
      expect(rendered).to have_selector('ul.tabs')
      expect(rendered).to have_selector('ul.tabs li', count: 3)
      expect(rendered).to have_selector('ul.tabs li.active', count: 1)
    end
  end
end
