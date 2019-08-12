require 'spec_helper'

describe RootController, type: :controller do
  subject { get :index }

  context 'when User is connected' do
    before do
      sign_in create(:user)
    end

    it { expect(subject).to redirect_to(dossiers_path) }
  end

  context 'when Instructeur is connected' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

    before do
      instructeur.procedures << procedure
      sign_in instructeur
    end

    it { expect(subject).to redirect_to(instructeur_procedures_path) }
  end

  context 'when Administrateur is connected' do
    before do
      sign_in create(:administrateur)
    end

    it { expect(subject).to redirect_to(admin_procedures_path) }
  end

  context 'when Administration is connected' do
    before do
      sign_in create(:administration)
    end

    it { expect(subject).to redirect_to(manager_root_path) }
  end

  context 'when nobody is connected' do
    render_views

    before do
      stub_request(:get, "https://api.github.com/repos/betagouv/tps/releases/latest")
        .to_return(:status => 200, :body => '{"tag_name": "plip", "body": "blabla", "published_at": "2016-02-09T16:46:47Z"}', :headers => {})

      subject
    end

    it { expect(response.body).to have_css('.landing') }
  end

  context "unified login" do
    render_views

    before do
      subject
    end

    it "won't have instructeur login link" do
      expect(response.body).to have_css("a[href='#{new_user_session_path}']")
    end
  end
end
