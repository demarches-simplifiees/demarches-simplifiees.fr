require 'spec_helper'

describe Admin::MailTemplatesController, type: :controller do
  let(:initiated_mail) { Mails::InitiatedMail.default }
  let(:procedure) { create :procedure }

  before do
    sign_in procedure.administrateur
  end

  describe 'GET index' do
    render_views

    subject { get :index, params: { procedure_id: procedure.id } }

    it { expect(subject.status).to eq 200 }
    it { expect(subject.body).to include("E-mails personnalisables") }
    it { expect(subject.body).to include(Mails::InitiatedMail::DISPLAYED_NAME) }
  end

  describe 'PATCH update' do
    let(:object) { 'plop modif' }
    let(:body) { 'plip modif' }

    before :each do
      patch :update,
        params: { procedure_id: procedure.id,
                  id: initiated_mail.class.const_get(:SLUG),
                  mail_template: { object: object, body: body }
                }
    end

    it { expect(response).to redirect_to admin_procedure_mail_templates_path(procedure) }

    context 'the mail template' do
      subject { procedure.reload ; procedure.initiated_mail }

      it { expect(subject.object).to eq(object) }
      it { expect(subject.body).to eq(body) }
    end
  end
end
