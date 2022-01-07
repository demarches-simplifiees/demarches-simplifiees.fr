describe Administrateurs::ProcedureAdministrateursController, type: :controller do
  let(:signed_in_admin) { create(:administrateur) }
  let(:other_admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, administrateurs: [signed_in_admin, other_admin]) }

  before do
    sign_in(signed_in_admin.user)
  end

  describe '#destroy' do
    subject do
      delete :destroy, params: { procedure_id: procedure.id, id: admin_to_remove.id }, format: :js, xhr: true
    end

    context 'when removing another admin' do
      let(:admin_to_remove) { other_admin }

      it 'removes the admin from the procedure' do
        subject
        expect(response.status).to eq(200)
        expect(flash[:notice]).to be_present
        expect(admin_to_remove.procedures.reload).not_to include(procedure)
      end
    end

    context 'when removing oneself from a procedure' do
      let(:admin_to_remove) { signed_in_admin }

      it 'denies the right for an admin to remove itself' do
        subject
        expect(response.status).to eq(200)
        expect(flash[:alert]).to be_present
        expect(admin_to_remove.procedures.reload).to include(procedure)
      end
    end
  end
end
