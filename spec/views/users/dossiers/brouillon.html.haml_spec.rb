describe 'users/dossiers/brouillon.html.haml', type: :view do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_notice, :with_service) }
  let(:dossier) { create(:dossier, state: Dossier.states.fetch(:brouillon), procedure: procedure) }
  let(:footer) { view.content_for(:footer) }
  let(:profile) { :user }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
    # allow(view) doesn't work because method is called inside partial
    ActionView::Base.any_instance.stub(:administrateur_signed_in?).and_return(profile == :administrateur)
  end

  subject! { render }

  context "as an user" do
    it 'affiche le libellé de la démarche' do
      expect(rendered).to have_text(dossier.procedure.libelle)
    end

    it 'affiche un lien vers la notice' do
      expect(response).to have_css("a[href*='/rails/active_storage/blobs/']", text: "Guide de la démarche")
      expect(rendered).not_to have_text("Ce lien est éphémère")
    end

    it 'affiche les boutons de validation' do
      expect(rendered).to have_selector('.send-dossier-actions-bar')
    end

    it 'prépare le footer' do
      expect(footer).to have_selector('footer')
    end

    context 'quand la démarche ne comporte pas de notice' do
      let(:procedure) { create(:procedure) }
      it { is_expected.not_to have_link("Guide de la démarche") }
    end
  end

  context "as an administrateur" do
    let(:profile) { :administrateur }

    before do
      create(:administrateur, user: dossier.user)
    end

    it 'affiche un avertissement à propos de la notice' do
      expect(rendered).to have_text("Ce lien est éphémère")
    end
  end
end
