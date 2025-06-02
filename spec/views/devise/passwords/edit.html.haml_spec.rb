# frozen_string_literal: true

require 'spec_helper'

describe 'devise/passwords/edit.html.haml', type: :view do
  let(:instructeur) { create :instructeur }
  let(:user) { instructeur.user }
  let(:complexity) { 3 }

  before(:each) do
    allow(view).to receive(:devise_error_messages!).and_return("")
    allow(view).to receive(:resource).and_return(user)
    allow(view).to receive(:populated_resource).and_return(user)
    allow(view).to receive(:resource_name).and_return(:user)
  end

  before do
    render
  end

  it 'renders' do
    expect(rendered).to have_selector("input[id=user_password][data-turbo-input-url-value='#{show_password_complexity_path(complexity)}']")
    expect(rendered).to have_selector('#password_complexity')
    expect(rendered).to have_selector('.fr-alert__title')
    expect(rendered).to have_selector('input[type=submit]')
  end
end
