describe Administrateurs::MailTemplatesController, type: :controller do
  render_views
  let(:procedure) { create :procedure }
  let(:initiated_mail) { Mails::InitiatedMail.default_for_procedure(procedure) }

  let(:admin) { create(:administrateur) }

  before do
    sign_in(procedure.administrateurs.first.user)
  end

  describe 'GET index' do
    render_views

    subject { get :index, params: { procedure_id: procedure.id } }

    it { expect(subject.status).to eq 200 }
    it { expect(subject.body).to include("Configuration des emails") }
    it { expect(subject.body).to include(Mails::InitiatedMail::DISPLAYED_NAME) }
  end

  describe '#preview' do
    let(:procedure) { create(:procedure, :with_logo, :with_service, administrateur: admin) }

    before do
      sign_in(admin.user)
      get :preview, params: { id: "initiated_mail", procedure_id: procedure.id }
    end

    it { expect(response).to have_http_status(:ok) }

    it 'displays the procedure logo' do
      expect(response.body).to have_css("img[src*='/rails/active_storage/blobs/']")
    end

    it 'displays the action buttons' do
      expect(response.body).to have_link('Consulter mon dossier')
    end

    it 'displays the service in the footer' do
      expect(response.body).to include(procedure.service.nom)
      expect(response.body).to include(procedure.service.telephone)
    end
  end

  describe 'PATCH update' do
    let(:mail_subject) { 'Mise à jour de votre démarche' }
    let(:mail_body) { '<div>Une mise à jour a été effectuée sur votre démarche n° --numéro du dossier--.</div>' }

    before :each do
      patch :update,
        params: {
          procedure_id: procedure.id,
          id: initiated_mail.class.const_get(:SLUG),
          mails_initiated_mail: { subject: mail_subject, rich_body: mail_body }
        }
    end

    it { expect(response).to redirect_to edit_admin_procedure_mail_template_path(procedure, initiated_mail.class.const_get(:SLUG)) }

    context 'with valid email template' do
      subject { procedure.reload; procedure.initiated_mail_template }

      it do
        expect(subject.subject).to eq(mail_subject)
        expect(subject.body).to eq(mail_body)
      end
    end

    context 'with invalid email template' do
      subject { procedure.reload; procedure.initiated_mail_template }
      let(:mail_body) { '<div>Une mise à jour a été effectuée sur votre démarche n° --numéro--.</div>' }

      it do
        expect(subject.body).not_to eq(mail_body)
        expect(response.body).to match("Le corps de l’email contient la balise &quot;numéro&quot; qui n’existe pas, veuillez la supprimer.")
      end
    end
  end
end
