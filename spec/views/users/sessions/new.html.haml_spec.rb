# frozen_string_literal: true

describe 'users/sessions/new', type: :view do
  let(:dossier) { create :dossier }

  before(:each) do
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(User.new)
  end

  before do
    assign(:user, User.new)
    render
  end

  it 'renders' do
    expect(rendered).to have_field('Adresse électronique')
    expect(rendered).to have_field('Mot de passe')
    expect(rendered).to have_button('Se connecter')
    if ENV['GOOGLE_CLIENT_ID'].present?
      expect(rendered).to have_link('Google')
    end
    if ENV['MICROSOFT_CLIENT_ID'].present?
      expect(rendered).to have_link('Microsoft')
    end
    if ENV['YAHOO_CLIENT_ID'].present?
      expect(rendered).to have_link('Yahoo!')
    end
    if ENV['TATOU_CLIENT_ID'].present?
      expect(rendered).to have_link('Tatou')
    end
    if ENV['SIPF_CLIENT_ID'].present?
      expect(rendered).to have_link('administration')
    end
    if ENV['FC_PARTICULIER_ID'].present?
      expect(rendered).to have_link('S’identifier avec FranceConnect')
    end
  end
end
