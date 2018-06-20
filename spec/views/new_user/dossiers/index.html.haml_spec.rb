require 'spec_helper'

describe 'new_user/dossiers/index.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:user_dossiers) { create_list(:dossier, 2, state: 'brouillon', user: user) }
  let(:dossiers_invites) { [] }
  let(:current_tab) { 'mes-dossiers' }

  before do
    assign(:user_dossiers, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:dossiers_invites, Kaminari.paginate_array(dossiers_invites).page(1))
    assign(:dossiers, Kaminari.paginate_array(user_dossiers).page(1))
    assign(:current_tab, current_tab)
    render
  end

  it 'affiche la liste des dossiers' do
    expect(rendered).to have_selector('.dossiers-table tbody tr', count: 2)
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

  context 'avec des dossiers invités' do
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
