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
    let(:gestionnaire) { create(:gestionnaire) }
    let(:procedure) { create(:procedure, :published) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

    before do
      gestionnaire.procedures << procedure
      sign_in gestionnaire
    end

    it { expect(subject).to redirect_to(procedures_path) }

    context 'and coming with old_ui param' do
      subject { get :index, params: { old_ui: 1 } }

      it { expect(subject).to redirect_to(backoffice_path) }
    end
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

    it { expect(subject).to redirect_to(administrations_path) }
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

    it "won't have gestionnaire login link" do
      expect(response.body).to have_css("a[href='#{new_user_session_path}']")
    end
  end
end
