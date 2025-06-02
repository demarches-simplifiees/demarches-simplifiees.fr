# frozen_string_literal: true

require 'spec_helper'

describe 'administrateurs/services/edit.html.haml', type: :view do
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
    it 'contains placeholder gov.pf for mails' do
      expect(rendered).to match(/gov.pf/)
      expect(rendered).to match(/7h30/)
      expect(rendered).to match(/Raiatea/)
    end
  end
end
