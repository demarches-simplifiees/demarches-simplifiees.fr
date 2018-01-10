describe Manager::ProceduresController, type: :controller do
  describe '#whitelist' do
    let(:administration) { create :administration }
    let!(:procedure) { create(:procedure) }

    before do
      sign_in administration
      post :whitelist, id: procedure.id
      procedure.reload
    end

    it { expect(procedure.whitelisted_at).not_to be_nil }
  end
end
