require 'spec_helper'

describe 'users/dossiers/brouillon.html.haml', type: :view do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_notice, :with_service, for_individual: true) }
  let(:dossier) { create(:dossier, :with_entreprise, state: Dossier.states.fetch(:brouillon), procedure: procedure) }
  let(:footer) { view.content_for(:footer) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'affiche le libellé de la démarche' do
    expect(rendered).to have_text(dossier.procedure.libelle)
  end

  it 'affiche un lien vers la notice' do
    expect(rendered).to have_link("Guide de la démarche", href: url_for(procedure.notice))
  end

  it 'affiche les boutons de validation' do
    expect(rendered).to have_selector('.send-dossier-actions-bar')
  end

  it 'prépare le footer' do
    expect(footer).to have_selector('footer')
  end

  context 'quand la démarche ne comporte pas de notice' do
    let(:procedure) { create(:procedure) }
    it { is_expected.not_to have_link("Guide de la démarche") }
  end
end
