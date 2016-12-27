require 'spec_helper'

describe 'admin/gestionnaires/index.html.haml', type: :view do
  let(:token) { 'super_token' }
  let(:admin) { create(:administrateur, api_token: token) }

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
    it { expect(rendered).to have_content('Aucun accompagnateur') }
  end

  context 'Ajout d\'un accompagnateur' do
    before do
      create(:gestionnaire, administrateurs: [admin])
      admin.reload
      assign(:gestionnaires, (smart_listing_create :gestionnaires,
                                                   admin.gestionnaires,
                                                   partial: "admin/gestionnaires/list",
                                                   array: true))
      render
    end
    it { expect(rendered).to match(/gest\d+@plop.com/) }
  end
end