require 'spec_helper'

describe 'new_user/dossiers/index.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:dossier_brouillon) { create(:dossier, state: 'brouillon', user: user) }
  let(:dossier_en_construction) { create(:dossier, state: 'en_construction', user: user) }
  let(:user_dossiers) { [dossier_brouillon, dossier_en_construction] }
  let(:dossiers_invites) { [] }
  let(:current_tab) { 'mes-dossiers' }

  before do
    allow(view).to receive(:new_demarche_url).and_return('#')
    assign(:user_dossiers, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossiers_invites, Kaminari.paginate_array(dossiers_invites).page(1))
    assign(:dossiers, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:current_tab, current_tab)
    render
  end

  it 'affiche la liste des dossiers' do
    expect(rendered).to have_selector('.dossiers-table tbody tr', count: 2)
  end

  it 'affiche les informations des dossiers' do
    dossier = user_dossiers.first
    expect(rendered).to have_text(dossier_brouillon.id)
    expect(rendered).to have_text(dossier_brouillon.procedure.libelle)
    expect(rendered).to have_link(dossier_brouillon.id, href: modifier_dossier_path(dossier_brouillon))

    expect(rendered).to have_text(dossier_en_construction.id)
    expect(rendered).to have_text(dossier_en_construction.procedure.libelle)
    expect(rendered).to have_link(dossier_en_construction.id, href: users_dossier_recapitulatif_path(dossier_en_construction))
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

    it 'n’affiche pas la barre d’onglets' do
      expect(rendered).not_to have_selector('ul.tabs')
    end
  end

  context 'quand il y a des dossiers invités' do
    let(:dossiers_invites) { create_list(:dossier, 1) }

    it 'affiche un titre adapté' do
      expect(rendered).to have_selector('h1', text: 'Dossiers')
    end

    it 'affiche la barre d’onglets' do
      expect(rendered).to have_selector('ul.tabs')
      expect(rendered).to have_selector('ul.tabs li', count: 2)
      expect(rendered).to have_selector('ul.tabs li.active', count: 1)
    end
  end
end
