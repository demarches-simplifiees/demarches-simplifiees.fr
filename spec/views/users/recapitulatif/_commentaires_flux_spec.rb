require 'spec_helper'

describe 'users/recapitulatif/_commentaires_flux.html.haml', type: :view, vcr: { cassette_name: 'views_users_recapitulatif_commentaires_flux' } do
  let(:dossier) { create(:dossier) }
  let(:dossier_id) { dossier.id }
  let(:email_commentaire) { 'mon_mail_de_commentaire@test.com' }

  let(:document_upload) { Rack::Test::UploadedFile.new("./spec/support/files/piece_justificative_0.pdf", 'application/pdf') }
  let(:pj) { create :piece_justificative, content: document_upload }

  let!(:commentaire) { create(:commentaire, dossier: dossier, email: email_commentaire, body: 'ma super description', piece_justificative: pj) }
  let(:body) { 'Commentaire de test' }

  before do
    assign(:facade, DossierFacades.new(dossier.id, dossier.user.email))
    render
  end

  context 'Affichage du flux de commentaire' do
    it 'l\'email du contact est présent' do
      expect(rendered).to have_selector('span[id=email_contact]')
    end

    it 'la date du commentaire est présent' do
      expect(rendered).to have_selector('span[id=created_at]')
    end

    it 'le corps du commentaire est présent' do
      expect(rendered).to have_selector('div[class=description][id=body]')
    end

    context 'when commentaire as PJ' do
      it 'commentaire present the link' do
        expect(rendered).to have_css('#piece_justificative')
      end
    end
  end

  context 'Affichage du formulaire de commentaire' do
    it 'Le formulaire envoie vers /dossiers/:dossier_id/commentaire en #POST' do
      expect(rendered).to have_selector("form[action='/users/dossiers/#{dossier_id}/commentaire'][method=post]")
    end

    it 'Champs de texte' do
      expect(rendered).to have_selector('textarea[id=texte_commentaire][name=texte_commentaire]')
    end

    describe 'File input' do
      it 'have file_input tag' do
        expect(rendered).to have_css('#piece_justificative_content')
      end
    end
  end
end
