describe 'users/dossiers/index.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:dossier_brouillon) { create(:dossier, state: Dossier.states.fetch(:brouillon), user: user) }
  let(:dossier_en_construction) { create(:dossier, state: Dossier.states.fetch(:en_construction), user: user) }
  let(:dossier_termine) { create(:dossier, state: Dossier.states.fetch(:accepte), user: user) }
  let(:user_dossiers) { [dossier_brouillon, dossier_en_construction, dossier_termine] }
  let(:dossiers_invites) { [] }
  let(:statut) { 'en-cours' }

  before do
    allow(view).to receive(:new_demarche_url).and_return('#')
    allow(controller).to receive(:current_user) { user }
    assign(:user_dossiers, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossiers_invites, Kaminari.paginate_array(dossiers_invites).page(1))
    assign(:dossiers_supprimes_recemment, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossiers_supprimes_definitivement, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossiers_traites, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossier_transfers, Kaminari.paginate_array([]).page(1))
    assign(:dossiers_close_to_expiration, Kaminari.paginate_array([]).page(1))
    assign(:statut, statut)
    render
  end

  it 'affiche la liste des dossiers' do
    expect(rendered).to have_selector('.dossiers-table tbody tr', count: 3)
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

  it 'n’affiche pas une alerte pour continuer à remplir un dossier' do
    expect(rendered).not_to have_selector('.fr-callout', count: 1)
  end

  context 'quand il y a un dossier en brouillon récemment mis à jour' do
    before do
      assign(:first_brouillon_recently_updated, dossier_brouillon)
      render
    end
    it 'affiche une alerte pour continuer à remplir un dossier' do
      expect(rendered).to have_selector('.fr-callout', count: 1)
      expect(rendered).to have_link(href: modifier_dossier_path(dossier_brouillon))
    end
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
      expect(rendered).to have_selector('h1', text: 'Mes dossiers')
    end

    it 'n’affiche la barre d’onglets' do
      expect(rendered).to have_selector('nav.tabs')
    end
  end

  context 'quand il y a des dossiers invités' do
    let(:dossiers_invites) { create_list(:dossier, 1) }

    it 'affiche un titre adapté' do
      expect(rendered).to have_selector('h1', text: 'Mes dossiers')
    end

    it 'affiche la barre d’onglets' do
      expect(rendered).to have_selector('nav.tabs')
      expect(rendered).to have_selector('nav.tabs li', count: 5)
      expect(rendered).to have_selector('nav.tabs li.active', count: 1)
    end
  end

  context 'where there is a traite dossier' do
    let(:dossiers_traites) { create_list(:dossier, 1) }

    it "displays the hide by user at button" do
      expect(rendered).to have_text("Supprimer le dossier")
    end
  end
end
