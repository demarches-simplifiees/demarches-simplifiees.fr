require 'spec_helper'

describe 'layouts/left_panels/_left_panel_admin_procedurescontroller_index.html.haml', type: :view do
  describe 'polynesian specific counter classes' do
    let(:current_administrateur) { create(:administrateur) }

    before do
      render partial: 'layouts/left_panels/left_panel_admin_procedurescontroller_index.html.haml', locals: { current_administrateur: current_administrateur }
    end

    subject { rendered }

    it { is_expected.to have_css('.badge.counter-draft') }
    it { is_expected.to have_css('.badge.counter-active') }
    it { is_expected.to have_css('.badge.counter-archived') }
  end
end
