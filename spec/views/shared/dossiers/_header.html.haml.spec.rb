describe 'dossiers/show/header.html.haml', type: :view do
  let(:procedure) { create(:procedure, :discarded) }
  let(:dossier) { create(:dossier, state: "brouillon", procedure: procedure) }

  before do
    sign_in dossier.user
  end

  subject! { render 'shared/dossiers/header.html.haml', dossier: dossier }

  context "when the procedure is discarded with a dossier en brouillon" do
    it 'affiche que la démarche est supprimée' do
      expect(rendered).to have_text("La démarche liée à votre dossier est supprimée")
      expect(rendered).to have_text("Vous pouvez toujours consulter votre dossier, mais il ne sera pas traité par l'administration")
    end

    it 'cannot download the dossier' do
      expect(rendered).not_to have_text("Tout le dossier")
    end
  end

  context "when the procedure is closed with a dossier en brouillon" do
    let(:procedure) { create(:procedure, :closed) }

    it 'affiche que la démarche est close' do
      expect(rendered).to have_text("La démarche liée à votre dossier est close")
      expect(rendered).to have_text("Vous pouvez toujours consulter votre dossier, mais il ne sera pas traité par l'administration")
    end

    it 'cannot download the dossier' do
      expect(rendered).not_to have_text("Tout le dossier")
    end
  end
end
