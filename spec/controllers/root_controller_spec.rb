require 'spec_helper'

describe RootController, type: :controller do

  subject { get :index }

  context 'when User is connected' do
    before do
      sign_in create(:user)
    end

    it { expect(subject).to redirect_to(users_dossiers_path) }
  end

  context 'when Gestionnaire is connected' do
    before do
      sign_in create(:gestionnaire)
    end

    it { expect(subject).to redirect_to(backoffice_dossiers_path) }
  end

  context 'when Administrateur is connected' do
    before do
      sign_in create(:administrateur)
    end

    it { expect(subject).to redirect_to(admin_procedures_path) }
  end

  context 'when nobody is connected' do
    render_views

    before do
      stub_request(:get, "https://api.github.com/repos/sgmap/tps/releases/latest").
          to_return(:status => 200, :body => '{"tag_name": "plip", "body": "blabla", "published_at": "2016-02-09T16:46:47Z"}', :headers => {})

      subject
    end

    it { expect(response.body).to have_css('#landing') }
  end
end