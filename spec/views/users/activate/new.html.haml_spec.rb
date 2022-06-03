require 'spec_helper'

describe 'users/activate/new.html.haml', type: :view do
  let(:user) { create :user }
  let(:complexity) { 3 }

  before do
    assign(:user, user)
    assign(:min_complexity, complexity)
    render
  end

  it 'renders' do
    expect(rendered).to have_selector('#user_email[disabled]')
    expect(rendered).to have_selector("input[id=user_password][data-turbo-input-url-value='#{show_password_complexity_path(complexity)}']")
    expect(rendered).to have_selector('.explication')
    expect(rendered).to have_selector('#complexity-bar')
    expect(rendered).to have_selector('#complexity-label')
    expect(rendered).to have_selector('input[type=submit]')
  end
end
