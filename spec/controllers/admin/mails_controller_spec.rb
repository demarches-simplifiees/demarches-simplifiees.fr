require 'spec_helper'

describe Admin::MailsController, type: :controller do
  let(:procedure) { create :procedure }

  before do
    sign_in procedure.administrateur
  end

  describe 'GET index' do
    subject { get :index, procedure_id: procedure.id }

    it { expect(subject.status).to eq 200 }
  end

  describe 'PATCH update' do
    let(:object) { 'plop modif' }
    let(:body) { 'plip modif' }

    context 'when is mail_received id' do
      subject { patch :update,
                      procedure_id: procedure.id,
                      id: procedure.mail_received.id,
                      mail_received: {
                          object: object,
                          body: body
                      } }

      it { expect(subject).to redirect_to admin_procedure_mails_path }

      describe 'values in database for mail received' do
        before do
          subject
          procedure.reload
        end

        it { expect(procedure.mail_received.object).to eq object }
        it { expect(procedure.mail_received.body).to eq body }
      end
    end
  end
end