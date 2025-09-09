# frozen_string_literal: true

describe Administrateurs::AttestationRefusTemplatesController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, administrateurs: [admin]) }

  before do
    sign_in(admin.user)
  end

  describe 'GET #edit' do
    subject { get :edit, params: { procedure_id: procedure.id } }

    context 'when no template exists' do
      it { expect(subject).to have_http_status(200) }
      it { expect(assigns(:attestation_refus_template)).not_to be_persisted }
    end

    context 'when a template exists' do
      let!(:attestation_refus_template) { create(:attestation_refus_template, procedure: procedure) }

      it { expect(subject).to have_http_status(200) }
      it { expect(assigns(:attestation_refus_template)).to eq(attestation_refus_template) }
    end
  end

  describe 'POST #create' do
    let(:attestation_refus_template_params) do
      {
        title: 'title',
        body: 'body',
        footer: 'footer',
        activated: true
      }
    end

    subject { post :create, params: { procedure_id: procedure.id, attestation_refus_template: attestation_refus_template_params } }

    context 'with valid params' do
      it 'creates the template' do
        expect { subject }.to change { procedure.reload.attestation_refus_templates.count }.by(1)
      end

      it 'redirects to edit path' do
        subject
        expect(response).to redirect_to edit_admin_procedure_attestation_refus_template_path(procedure)
      end
    end

    context 'with invalid params' do
      let(:attestation_refus_template_params) { { title: 'title --invalid_tag--' } }

      it 'does not create the template' do
        expect { subject }.not_to change { procedure.reload.attestation_refus_templates.count }
      end

      it 'renders edit' do
        subject
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:attestation_refus_template) { create(:attestation_refus_template, procedure: procedure, title: 'old title') }
    let(:attestation_refus_template_params) { { title: 'new title' } }

    subject { patch :update, params: { procedure_id: procedure.id, attestation_refus_template: attestation_refus_template_params } }

    context 'with valid params' do
      it 'updates the template' do
        subject
        expect(attestation_refus_template.reload.title).to eq('new title')
      end

      it 'redirects to edit path' do
        subject
        expect(response).to redirect_to edit_admin_procedure_attestation_refus_template_path(procedure)
      end
    end

    context 'with invalid params' do
      let(:attestation_refus_template_params) { { title: 'title --invalid_tag--' } }

      it 'does not update the template' do
        subject
        expect(attestation_refus_template.reload.title).to eq('old title')
      end

      it 'renders edit' do
        subject
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'GET #preview' do
    let!(:attestation_refus_template) { create(:attestation_refus_template, procedure: procedure) }

    subject { get :preview, params: { procedure_id: procedure.id }, format: 'pdf' }

    it { expect(subject).to have_http_status(200) }
    it { expect(subject.content_type).to eq('application/pdf') }
  end
end