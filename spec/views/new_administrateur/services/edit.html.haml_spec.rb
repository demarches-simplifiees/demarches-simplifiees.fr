require 'spec_helper'

describe 'new_administrateur/services/edit.html.haml', type: :view do

  # FIXME: delete this when support for pj champ is generalized
  before { allow(view).to receive(:current_administrateur).and_return(create(:administrateur)) }

  describe 'Polynesia adaptations' do
    let(:service) { create(:service) }
    let(:procedure) { create(:procedure) }
    before do
      assign(:service, service)
      assign(:procedure, procedure)
      render
    end
    it "siret or numero tahiti is useless and should be present" do
      expect(rendered).not_to match(/siret|numéro TAHITI/im)
    end
    it 'contains placeholder at papeete' do
      expect(rendered).to match(/Papeete/)
    end
    it 'contains placeholder gov.pf for mails' do
      expect(rendered).to match(/gov.pf/)
    end
  end
end
