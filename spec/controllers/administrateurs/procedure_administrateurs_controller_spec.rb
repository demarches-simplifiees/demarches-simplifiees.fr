describe Administrateurs::ProcedureAdministrateursController, type: :controller do
  let(:signed_in_admin) { create(:administrateur) }
  let(:other_admin) { create(:administrateur) }
  let!(:administrateurs_procedure) { create(:administrateurs_procedure, administrateur: signed_in_admin, procedure: procedure, manager: manager) }
  let!(:procedure) { create(:procedure, administrateurs: [other_admin]) }
  render_views

  before do
    sign_in(signed_in_admin.user)
  end

  describe '#create' do
    context 'as manager' do
      let(:manager) { true }
      subject { post :create, params: { procedure_id: procedure.id, administrateur: { email: create(:administrateur).email } }, format: :turbo_stream }
      it { is_expected.to have_http_status(:forbidden) }
    end
  end

  describe '#destroy' do
    let(:manager) { false }
    subject do
      delete :destroy, params: { procedure_id: procedure.id, id: admin_to_remove.id }, format: :turbo_stream
    end

    context 'when removing another admin' do
      let(:admin_to_remove) { other_admin }

      it 'removes the admin from the procedure' do
        subject
        expect(response).to have_http_status(:ok)
        expect(subject.body).to include('alert-success')
        expect(admin_to_remove.procedures.reload).not_to include(procedure)
      end
    end

    context 'when removing oneself from a procedure' do
      let(:admin_to_remove) { signed_in_admin }

      it 'denies the right for an admin to remove itself' do
        subject
        expect(response).to have_http_status(:ok)
        expect(subject.body).to include('alert-danger')
        expect(admin_to_remove.procedures.reload).to include(procedure)
      end
    end
  end
end
