# frozen_string_literal: true

describe 'users/dossiers/index', type: :view do
  let(:user) { create(:user) }
  let(:procedure_accuse_lecture) { create(:procedure, :accuse_lecture) }
  let(:dossier_brouillon) { create(:dossier, state: Dossier.states.fetch(:brouillon), user: user) }
  let(:dossier_en_construction) { create(:dossier, state: Dossier.states.fetch(:en_construction), user: user) }
  let(:dossier_en_construction_with_accuse_lecture) { create(:dossier, state: Dossier.states.fetch(:en_construction), user: user, procedure: procedure_accuse_lecture) }
  let(:dossier_termine) { create(:dossier, state: Dossier.states.fetch(:accepte), user: user) }
  let(:dossier_termine_with_accuse_lecture) { create(:dossier, state: Dossier.states.fetch(:accepte), user: user, procedure: procedure_accuse_lecture) }
  let(:dossiers_invites) { [] }
  let(:user_dossiers) { Kaminari.paginate_array([dossier_brouillon, dossier_en_construction, dossier_termine, dossier_en_construction_with_accuse_lecture, dossier_termine_with_accuse_lecture]).page(1) }
  let(:statut) { 'en-cours' }
  let(:filter) { DossiersFilter.new(user, ActionController::Parameters.new(random_param: 'random_param')) }

  before do |config|
    allow(view).to receive(:new_demarche_url).and_return('#')
    allow(controller).to receive(:current_user) { user }
    assign(:user_dossiers, user_dossiers)
    assign(:dossiers_invites, Kaminari.paginate_array(dossiers_invites).page(1))
    assign(:dossiers_supprimes, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossiers_traites, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossier_transferes, Kaminari.paginate_array([]).page(1))
    assign(:dossiers_close_to_expiration, Kaminari.paginate_array([]).page(1))
    assign(:dossiers, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:procedures_for_select, user_dossiers.map(&:procedure))
    assign(:statut, statut)
    assign(:filter, filter)
    assign(:all_dossiers_uniq_procedures_count, 0)

    render if !config.metadata[:caching]
  end

  it 'affiche les dossiers' do
    expect(rendered).to have_selector('.card', count: 5)
  end

  it 'affiche les informations des dossiers' do
    dossier = user_dossiers.first
    expect(rendered).to have_text(dossier_brouillon.id.to_s)
    expect(rendered).to have_text(dossier_brouillon.procedure.libelle)
    expect(rendered).to have_link(dossier_brouillon.procedure.libelle, href: brouillon_dossier_path(dossier_brouillon))

    expect(rendered).to have_text(dossier_en_construction.id.to_s)
    expect(rendered).to have_text(dossier_en_construction.procedure.libelle)
    expect(rendered).to have_link(dossier_en_construction.procedure.libelle, href: dossier_path(dossier_en_construction))

    expect(rendered).to have_selector('.fr-badge', text: 'traité', count: 1)
    expect(rendered).to have_selector('.fr-badge', text: 'en construction', count: 2)
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
    let(:user_dossiers) { [] }
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
      expect(rendered).to have_selector('nav.fr-tabs')
    end
  end

  context 'quand il y a des dossiers invités' do
    let(:dossiers_invites) { create_list(:dossier, 1) }

    it 'affiche un titre adapté' do
      expect(rendered).to have_selector('h1', text: 'Mes dossiers')
    end

    it 'affiche la barre d’onglets' do
      expect(rendered).to have_selector('nav.fr-tabs')
      expect(rendered).to have_selector('nav.fr-tabs li', count: 4)
      expect(rendered).to have_selector('nav.fr-tabs li.active', count: 1)
    end
  end

  context 'where there is a traite dossier' do
    let(:dossiers_traites) { create_list(:dossier, 1) }

    it "displays the hide by user at button" do
      expect(rendered).to have_text("Mettre à la corbeille")
    end
  end

  context 'caching', caching: true do
    it "works" do
      expect(user_dossiers).to receive(:present?).thrice
      2.times { render; user.reload }
    end

    it "cache key depends on statut" do
      expect(user_dossiers).to receive(:present?).exactly(4).times
      render

      assign(:statut, "termines")
      user.reload

      render
    end

    it "cache key depends on dossier updated_at" do
      expect(user_dossiers).to receive(:present?).exactly(4).times
      render

      travel(1.minute)

      dossier_termine.touch
      user.reload

      render
    end

    it "cache key depends on dossiers list" do
      render
      expect(rendered).to have_text(/5\s+en cours/)

      assign(:user_dossiers, Kaminari.paginate_array(user_dossiers.concat([create(:dossier, :en_construction, user: user)])).page(1))
      user.reload

      render
      expect(rendered).to have_text(/6\s+en cours/)
    end

    it "cache key depends on dossier invites" do
      expect(user_dossiers).to receive(:present?).exactly(4).times
      render

      create(:invite, user:)
      user.reload

      render
    end

    it "cache key depends on dossier deletion" do
      expect(user_dossiers).to receive(:present?).exactly(4).times
      render

      travel(1.minute)

      dossier_termine.hide_and_keep_track!(:automatic, :expired)
      user.reload

      render
    end
  end
end
