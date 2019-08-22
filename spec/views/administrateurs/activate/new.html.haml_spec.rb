require 'spec_helper'

describe 'administrateurs/activate/new.html.haml', type: :view do
  let(:admin) { create :administrateur }
  let(:strength_path) { test_password_strength_path(PASSWORD_COMPLEXITY_FOR_ADMIN) }

  before do
    assign(:administrateur, admin)
    render
  end

  it 'renders' do
    expect(rendered).to have_selector('#administrateur_email[disabled]')
    expect(rendered).to have_selector("input[id=administrateur_password][data-url='#{strength_path}']")
    expect(rendered).to have_selector('.explication')
    expect(rendered).to have_selector('#strength-bar')
    expect(rendered).to have_selector('#strength-label')
    expect(rendered).to have_selector('input[type=submit]')
  end
end
