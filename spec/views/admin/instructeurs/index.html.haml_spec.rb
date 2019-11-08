require 'spec_helper'

describe 'admin/instructeurs/index.html.haml', type: :view do
  let(:admin) { create(:administrateur) }

  before do
    assign(:instructeurs, (smart_listing_create :instructeurs,
      admin.instructeurs,
      partial: "admin/instructeurs/list",
      array: true))
    assign(:instructeur, create(:instructeur))
  end

  context 'Aucun instructeur' do
    before do
      render
    end
    it { expect(rendered).to have_content('Aucun instructeur') }
  end

  context 'Ajout d\'un instructeur' do
    before do
      create(:instructeur, administrateurs: [admin])
      admin.reload
      assign(:instructeurs, (smart_listing_create :instructeurs,
        admin.instructeurs,
        partial: "admin/instructeurs/list",
        array: true))
      render
    end
    it { expect(rendered).to match(/inst\d+@inst.com/) }
  end
end
