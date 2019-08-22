require 'spec_helper'

describe 'users/activate/new.html.haml', type: :view do
  let(:user) { create :user }
  let(:strength_path) { '/users/passwords/test_strength/3' }

  before do
    assign(:test_password_strength, strength_path)
    assign(:user, user)
    render
  end

  it 'renders' do
    expect(rendered).to have_selector('#user_email[disabled]')
    expect(rendered).to have_selector("input[id=user_password][data-url='#{strength_path}']")
    expect(rendered).to have_selector('.explication')
    expect(rendered).to have_selector('#strength-bar')
    expect(rendered).to have_selector('#strength-label')
    expect(rendered).to have_selector('input[type=submit]')
  end
end
