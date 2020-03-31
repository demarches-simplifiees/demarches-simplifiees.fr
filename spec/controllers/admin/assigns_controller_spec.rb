describe Admin::AssignsController, type: :controller do
  let(:admin) { create(:administrateur) }

  before do
    sign_in(admin.user)
  end

  describe 'GET #show' do
    let(:procedure) { create :procedure, administrateur: admin, instructeurs: [instructeur_assigned_1, instructeur_assigned_2] }
    let!(:instructeur_assigned_1) { create :instructeur, email: 'instructeur_1@ministere_a.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_assigned_2) { create :instructeur, email: 'instructeur_2@ministere_b.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_not_assigned_1) { create :instructeur, email: 'instructeur_3@ministere_a.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_not_assigned_2) { create :instructeur, email: 'instructeur_4@ministere_b.gouv.fr', administrateurs: [admin] }
    let(:filter) { nil }

    subject! { get :show, params: { procedure_id: procedure.id, filter: filter } }

    it { expect(response.status).to eq(200) }

    it 'sets the assigned and not assigned instructeurs' do
      expect(assigns(:instructeurs_assign)).to match_array([instructeur_assigned_1, instructeur_assigned_2])
      expect(assigns(:instructeurs_not_assign)).to match_array([instructeur_not_assigned_1, instructeur_not_assigned_2])
    end

    context 'with a search filter' do
      let(:filter) { '@ministere_a.gouv.fr' }

      it 'filters the unassigned instructeurs' do
        expect(assigns(:instructeurs_not_assign)).to match_array([instructeur_not_assigned_1])
      end

      it 'does not filter the assigned instructeurs' do
        expect(assigns(:instructeurs_assign)).to match_array([instructeur_assigned_1, instructeur_assigned_2])
      end

      context 'when the filter has spaces or a mixed case' do
        let(:filter) { ' @ministere_A.gouv.fr  ' }

        it 'trims spaces and ignores the case' do
          expect(assigns(:instructeurs_not_assign)).to match_array([instructeur_not_assigned_1])
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:procedure) { create :procedure, administrateur: admin }
    let(:instructeur) { create :instructeur, administrateurs: [admin] }

    subject { put :update, params: { instructeur_id: instructeur.id, procedure_id: procedure.id, to: 'assign' } }

    it { expect(subject).to redirect_to admin_procedure_assigns_path(procedure_id: procedure.id) }

    context 'when assignement is valid' do
      before do
        subject
      end

      it { expect(flash[:notice]).to be_present }
    end
  end
end
