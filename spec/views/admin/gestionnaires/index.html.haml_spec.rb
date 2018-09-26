require 'spec_helper'

describe 'admin/gestionnaires/index.html.haml', type: :view do
  let(:admin) { create(:administrateur) }

  before do
    assign(:gestionnaires, (smart_listing_create :gestionnaires,
      admin.gestionnaires,
      partial: "admin/gestionnaires/list",
      array: true))
    assign(:gestionnaire, Gestionnaire.new())
  end

  context 'Aucun gestionnaire' do
    before do
      render
    end
    it { expect(rendered).to have_content('Aucun instructeur') }
  end

  context 'Ajout d\'un instructeur' do
    before do
      create(:gestionnaire, administrateurs: [admin])
      admin.reload
      assign(:gestionnaires, (smart_listing_create :gestionnaires,
        admin.gestionnaires,
        partial: "admin/gestionnaires/list",
        array: true))
      render
    end
    it { expect(rendered).to match(/gest\d+@gest.com/) }
  end
end
