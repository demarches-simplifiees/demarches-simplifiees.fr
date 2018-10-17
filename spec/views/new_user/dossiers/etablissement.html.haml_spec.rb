require 'spec_helper'

describe 'new_user/dossiers/etablissement.html.haml', type: :view do
  let(:etablissement) { create(:etablissement, :with_exercices) }
  let(:dossier) { create(:dossier, etablissement: etablissement) }
  let(:footer) { view.content_for(:footer) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'affiche les informations de l’établissement' do
    expect(rendered).to have_text(etablissement.entreprise_raison_sociale)
    expect(rendered).to have_text(etablissement.siret)
  end

  it 'n’affiche pas publiquement les derniers exercices comptables' do
    expect(rendered).not_to have_text(number_to_currency(etablissement.exercices.first.ca))
  end

  context 'quand l’établissement est une association' do
    let(:etablissement) { create(:etablissement, :is_association) }

    it 'affiche les informations de l’association' do
      expect(rendered).to have_text(etablissement.association_titre)
    end
  end

  it 'prépare le footer' do
    expect(footer).to have_selector('footer')
  end
end
