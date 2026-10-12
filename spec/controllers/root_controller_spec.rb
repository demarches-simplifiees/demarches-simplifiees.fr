# frozen_string_literal: true

describe RootController, type: :controller do
  subject { get :index }

  context 'when User is connected' do
    before do
      sign_in create(:user)
    end

    it { expect(subject).to redirect_to(dossiers_path) }
  end

  context 'when Expert is connected' do
    before do
      sign_in(users.expert)
    end

    it { expect(subject).to redirect_to(expert_all_avis_path) }
  end

  context 'when Instructeur is connected' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

    before do
      instructeur.groupe_instructeurs << procedure.defaut_groupe_instructeur
      sign_in(instructeur.user)
    end

    it { expect(subject).to redirect_to(instructeur_procedures_path) }
  end

  context 'when Administrateur is connected' do
    before do
      sign_in(administrateurs.default.user)
    end

    it { expect(subject).to redirect_to(admin_procedures_path) }
  end

  context 'when Administration is connected' do
    before do
      sign_in create(:super_admin)
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

    it "affiche le marqueur numerique.gouv à la place du logo DINUM" do
      expect(response.body).to have_link("numerique.gouv", href: "https://www.numerique.gouv.fr/")
      expect(response.body).to have_css("footer img.hidden-on-dark-theme[src*='logo-numerique-gouv'][alt='numerique.gouv']")
      expect(response.body).to have_css("footer img.hidden-on-light-theme[src*='logo-numerique-gouv-dark'][alt='numerique.gouv']")
      expect(response.body).not_to have_css("img[src*='logo-dinum']")
    end
  end

  context "unified login" do
    render_views

    before do
      subject
    end

    it "won't have instructeur login link" do
      expect(response.body).to have_css("a[href='#{new_user_session_path(with_proconnect: true)}']")
    end
  end

  describe '#administration' do
    render_views

    it 'links to the release notes of administrateurs, instructeurs and usagers' do
      get :administration

      expect(response.body).to have_link("Voir les nouveautés", href: release_notes_path(categories: %w[administrateur instructeur usager]))
    end
  end
end
