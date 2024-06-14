describe Administrateurs::ExpertsProceduresController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create :procedure, administrateur: admin }

  before do
    sign_in(admin.user)
  end

  describe '#index' do
    subject do
      get :index, params: { procedure_id: procedure.id }
    end

    before do
      subject
    end

    it { expect(response.status).to eq 200 }
  end

  describe '#create' do
    let(:expert) { create(:expert) }
    let(:expert2) { create(:expert) }

    subject { post :create, params: }
    before { subject }

    context 'when inviting multiple valid experts' do
      let(:params) { { procedure_id: procedure.id, emails: [expert.email, expert2.email] } }

      it do
        expect(procedure.experts.include?(expert)).to be_truthy
        expect(procedure.experts.include?(expert2)).to be_truthy
        expect(flash.notice).to be_present
        expect(assigns(:maybe_typo)).to eq([])
        expect(response).to have_http_status(:success)
      end
    end

    context 'when inviting expert using an email with typos' do
      let(:params) { { procedure_id: procedure.id, emails: ['martin@oraneg.fr'] } }

      it 'warns' do
        expect(flash.alert).to be_present
        expect(assigns(:maybe_typo)).to eq(['martin@oraneg.fr'])
        expect(response).to have_http_status(:success)
      end
    end

    context 'when forcing email with typos' do
      let(:maybe_typo) { 'martin@oraneg.fr' }
      let(:params) { { procedure_id: procedure.id, maybe_typo: } }

      it 'works' do
        expect(User.exists?(email: maybe_typo)).to be_truthy
        expect(procedure.experts.include?(User.first(email: maybe_typo))).to be_truthy
        expect(flash.notice).to be_present
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe '#update' do
    let(:expert) { create(:expert) }
    let(:expert_procedure) { create(:experts_procedure, procedure: procedure, expert: expert) }

    subject do
      put :update, params: {
        id: expert_procedure.id,
        procedure_id: procedure.id,
        experts_procedure: {
          allow_decision_access: true
        }
      }, format: :js
    end

    before do
      subject
    end

    it 'updates the record' do
      expect(expert_procedure.allow_decision_access).to be false
      subject
      expect(expert_procedure.reload.allow_decision_access).to be true
    end
  end

  describe '#delete' do
    let(:expert) { create(:expert) }
    let(:expert_procedure) { ExpertsProcedure.create(expert: expert, procedure: procedure) }

    subject do
      delete :destroy, params: { procedure_id: procedure.id, id: expert_procedure.id }
    end

    before do
      subject
      expert_procedure.reload
    end

    context 'of multiple experts' do
      it { expect(expert_procedure.revoked_at).to be_present }
      it { expect(flash.notice).to be_present }
      it { expect(response).to redirect_to(admin_procedure_experts_path(procedure)) }
    end
  end
end
