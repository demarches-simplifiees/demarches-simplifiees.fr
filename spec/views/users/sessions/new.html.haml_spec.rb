require 'spec_helper'

describe 'users/sessions/new.html.haml', type: :view do
  let(:dossier) { create :dossier }

  before(:each) do
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource_name).and_return(:user)
  end

  before do
    assign(:user, User.new)
    render
  end

  it 'renders' do
    expect(rendered).to have_field('Email')
    expect(rendered).to have_field('Mot de passe')
    expect(rendered).to have_button('Se connecter')
  end
end
