require 'spec_helper'

describe Admin::MailTemplatesController, type: :controller do
  let(:procedure) { create :procedure }
  let(:initiated_mail) { Mails::InitiatedMail.default_for_procedure(procedure) }

  before do
    sign_in procedure.administrateurs.first
  end

  describe 'GET index' do
    render_views

    subject { get :index, params: { procedure_id: procedure.id } }

    it { expect(subject.status).to eq 200 }
    it { expect(subject.body).to include("E-mails personnalisables") }
    it { expect(subject.body).to include(Mails::InitiatedMail::DISPLAYED_NAME) }
  end

  describe 'PATCH update' do
    let(:mail_subject) { 'plop modif' }
    let(:mail_body) { 'plip modif' }

    before :each do
      patch :update,
        params: {
          procedure_id: procedure.id,
          id: initiated_mail.class.const_get(:SLUG),
          mail_template: { subject: mail_subject, body: mail_body }
        }
    end

    it { expect(response).to redirect_to edit_admin_procedure_mail_template_path(procedure, initiated_mail.class.const_get(:SLUG)) }

    context 'the mail template' do
      subject { procedure.reload; procedure.initiated_mail_template }

      it { expect(subject.subject).to eq(mail_subject) }
      it { expect(subject.body).to eq(mail_body) }
    end
  end
end
