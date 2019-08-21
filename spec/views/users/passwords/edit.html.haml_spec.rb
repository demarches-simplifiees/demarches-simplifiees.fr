require 'spec_helper'

describe 'users/passwords/edit.html.haml', type: :view do
  let(:user) { create :user }
  let(:strength_path) { '/users/passwords/test_strength/3' }

  before(:each) do
    allow(view).to receive(:devise_error_messages!).and_return("")
    allow(view).to receive(:resource).and_return(user)
    allow(view).to receive(:resource_name).and_return(:user)
  end

  before do
    assign(:test_password_strength, strength_path)
    render
  end

  it 'renders' do
    expect(rendered).to have_selector("input[id=user_password][data-url='#{strength_path}']")
    expect(rendered).to have_selector('.explication')
    expect(rendered).to have_selector('#strength-bar')
    expect(rendered).to have_selector('#strength-label')
    expect(rendered).to have_selector('input[type=submit]')
  end
end
