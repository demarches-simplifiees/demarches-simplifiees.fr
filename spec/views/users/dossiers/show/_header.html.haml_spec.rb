describe 'users/dossiers/show/header.html.haml', type: :view do
  let(:dossier) { create(:dossier, :en_construction, procedure: create(:procedure)) }
  let(:user) { dossier.user }

  before do
    sign_in user
  end

  subject! { render 'users/dossiers/show/header.html.haml', dossier: dossier }

  it 'affiche les informations du dossier' do
    expect(rendered).to have_text(dossier.procedure.libelle)
    expect(rendered).to have_text("Dossier nº #{dossier.id}")
    expect(rendered).to have_text("en construction")

    expect(rendered).to have_selector("nav.tabs")
    expect(rendered).to have_link("Résumé", href: dossier_path(dossier))
    expect(rendered).to have_link("Demande", href: demande_dossier_path(dossier))
  end

  context "when the procedure is closed with a dossier en construction" do
    let(:procedure) { create(:procedure, :closed) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

    it "n'affiche pas de banner" do
      expect(rendered).not_to have_text("La démarche liée à votre dossier est close")
    end

    it 'can download the dossier' do
      expect(rendered).to have_text("Tout le dossier")
    end
  end

  context "when the procedure is discarded with a dossier en construction" do
    let(:procedure) { create(:procedure, :with_service, :discarded) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

    it 'affiche que la démarche est supprimée' do
      expect(rendered).to have_text("La démarche liée à votre dossier est supprimée")
      expect(rendered).to have_text("Vous pouvez toujours consulter votre dossier, mais il n’est plus possible de le modifier")
    end

    it 'can download the dossier' do
      expect(rendered).to have_text("Tout le dossier")
    end
  end

  context "when the procedure is discarded with a dossier terminé" do
    let(:procedure) { create(:procedure, :with_service, :discarded) }
    let(:dossier) { create(:dossier, :accepte, procedure: procedure) }

    it 'affiche que la démarche est supprimée' do
      expect(rendered).to have_text("La démarche liée à votre dossier est supprimée")
      expect(rendered).to have_text("Votre dossier a été traité par l'administration, aucune action n'est possible")
    end

    it 'can download the dossier' do
      expect(rendered).to have_text("Tout le dossier")
    end
  end

  context "when user is invited" do
    context "when the procedure is closed with a dossier en construction" do
      let(:procedure) { create(:procedure, :closed) }
      let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let(:user) { create(:user) }

      before do
        create(:invite, user: user, dossier: dossier)
      end

      it "n'affiche pas de banner" do
        expect(rendered).not_to have_text("La démarche liée à votre dossier est close")
      end

      it 'can not download the dossier' do
        expect(rendered).not_to have_text("Tout le dossier")
      end
    end
  end
end
