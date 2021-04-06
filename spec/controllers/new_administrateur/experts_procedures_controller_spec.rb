describe NewAdministrateur::ExpertsProceduresController, type: :controller do
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

    subject do
      post :create, params: {
        procedure_id: procedure.id,
        emails: "[\"#{expert.email}\",\"#{expert2.email}\"]"
      }
    end

    before do
      subject
    end

    context 'of multiple experts' do
      it { expect(procedure.experts.include?(expert)).to be_truthy }
      it { expect(procedure.experts.include?(expert2)).to be_truthy }
      it { expect(flash.notice).to be_present }
      it { expect(response).to redirect_to(admin_procedure_experts_path(procedure)) }
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
