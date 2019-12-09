require 'spec_helper'

describe 'layouts/left_panels/_left_panel_admin_procedurescontroller_index.html.haml', type: :view do
  let(:current_administrateur) { create(:administrateur) }
  let(:user) { current_administrateur.user }

  before do
    allow(view).to receive(:multiple_devise_profile_connect?).and_return(true)
    allow(view).to receive(:instructeur_signed_in?).and_return(true)
    sign_in user
    render partial: 'layouts/left_panels/left_panel_admin_procedurescontroller_index.html.haml', locals: { current_administrateur: current_administrateur }
  end

  subject { rendered }

  it 'should have polynesian css' do
    is_expected.to have_css('.badge.counter-draft')
    is_expected.to have_css('.badge.counter-active')
    is_expected.to have_css('.badge.counter-closed')
  end
end
