describe Administrateurs::ArchivesController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create :procedure, administrateur: admin, groupe_instructeurs: [groupe_instructeur1, groupe_instructeur2] }
  let(:groupe_instructeur1) { create(:groupe_instructeur) }
  let(:groupe_instructeur2) { create(:groupe_instructeur) }

  describe 'GET #index' do
    subject { get :index, params: { procedure_id: procedure.id } }

    context 'when logged out' do
      it { is_expected.to have_http_status(302) }
    end
    context 'when logged in' do
      before do
        sign_in(admin.user)
      end

      it { is_expected.to have_http_status(200) }

      it 'use all procedure.groupe_instructeurs' do
        expect(Archive).to receive(:for_groupe_instructeur).with([groupe_instructeur1, groupe_instructeur2]).and_return([])
        subject
      end
    end
  end
  describe 'GET #create' do
    subject { post :create, params: { procedure_id: procedure.id, month: '22-06', type: 'monthly' } }

    context 'when logged out' do
      it { is_expected.to have_http_status(302) }
    end
    context 'when logged in' do
      before do
        sign_in(admin.user)
      end

      it { is_expected.to redirect_to(admin_procedure_archives_path(procedure)) }
      it 'enqueue the creation job' do
        expect { subject }.to have_enqueued_job(ArchiveCreationJob).with(procedure, an_instance_of(Archive), admin)
      end
    end
  end
end
