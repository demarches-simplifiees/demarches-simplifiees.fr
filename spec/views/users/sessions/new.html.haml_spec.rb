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
    if ENV['GOOGLE_CLIENT_ID'].present?
      expect(rendered).to have_link('Gmail, Google')
    end
    if ENV['MICROSOFT_CLIENT_ID'].present?
      expect(rendered).to have_link('Hotmail, Office365')
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
