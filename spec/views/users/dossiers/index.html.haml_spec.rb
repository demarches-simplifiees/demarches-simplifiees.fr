describe 'users/dossiers/index', type: :view do
  let(:user) { create(:user) }
  let(:dossier_brouillon) { create(:dossier, state: Dossier.states.fetch(:brouillon), user: user) }
  let(:dossier_en_construction) { create(:dossier, state: Dossier.states.fetch(:en_construction), user: user) }
  let(:dossier_termine) { create(:dossier, state: Dossier.states.fetch(:accepte), user: user) }
  let(:user_dossiers) { [dossier_brouillon, dossier_en_construction, dossier_termine] }
  let(:dossiers_invites) { [] }
  let(:statut) { 'en-cours' }
  let(:filter) { DossiersFilter.new(user, ActionController::Parameters.new(random_param: 'random_param')) }

  before do
    allow(view).to receive(:new_demarche_url).and_return('#')
    allow(controller).to receive(:current_user) { user }
    assign(:user_dossiers, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossiers_invites, Kaminari.paginate_array(dossiers_invites).page(1))
    assign(:dossiers_supprimes_recemment, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossiers_supprimes_definitivement, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossiers_traites, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossier_transferes, Kaminari.paginate_array([]).page(1))
    assign(:dossiers_close_to_expiration, Kaminari.paginate_array([]).page(1))
    assign(:dossiers, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:statut, statut)
    assign(:filter, filter)
    render
  end

  it 'affiche les dossiers' do
    expect(rendered).to have_selector('.card', count: 3)
  end

  it 'affiche les informations des dossiers' do
    dossier = user_dossiers.first
    expect(rendered).to have_text(dossier_brouillon.id.to_s)
    expect(rendered).to have_text(dossier_brouillon.procedure.libelle)
    expect(rendered).to have_link(dossier_brouillon.procedure.libelle, href: brouillon_dossier_path(dossier_brouillon))

    expect(rendered).to have_text(dossier_en_construction.id.to_s)
    expect(rendered).to have_text(dossier_en_construction.procedure.libelle)
    expect(rendered).to have_link(dossier_en_construction.procedure.libelle, href: dossier_path(dossier_en_construction))
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
      expect(rendered).to have_link(href: brouillon_dossier_path(dossier_brouillon))
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

  context 'quand le dossier a été supprimé' do
    let(:dossiers_supprimes_definitivement) { create(:deleted_dossier, user_id: user.id) }
    
    before do
      assign(:dossiers, Kaminari.paginate_array([dossiers_supprimes_definitivement]).page(1))
      assign(:statut, 'dossiers-supprimes-definitivement')
      render
    end

    it 'affiche les informations des dossiers' do
      dossier = dossiers_supprimes_definitivement
      expect(rendered).to have_text(dossiers_supprimes_definitivement.dossier_id.to_s)
      expect(rendered).to have_text(dossiers_supprimes_definitivement.procedure.libelle)
      expect(rendered).to have_text(I18n.t(dossiers_supprimes_definitivement.reason, scope: 'activerecord.attributes.deleted_dossier.reason'))
    end

    context 'quand la procédure a été supprimée' do
      before do
        dossiers_supprimes_definitivement.procedure.discard_and_keep_track!(dossiers_supprimes_definitivement.procedure.administrateurs.first)
        render
      end
      it 'affiche les informations des dossiers et ne déclenche pas d\'exception' do
        dossier = dossiers_supprimes_definitivement
        expect(rendered).to have_text(dossiers_supprimes_definitivement.dossier_id.to_s)
        expect(rendered).to have_text(dossiers_supprimes_definitivement.procedure.libelle)
        expect(rendered).to have_text(I18n.t(dossiers_supprimes_definitivement.reason, scope: 'activerecord.attributes.deleted_dossier.reason'))
      end
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
