# frozen_string_literal: true

describe Administrateurs::ArchivesController, type: :controller do
  let(:admin) { administrateurs(:default_admin) }
  let(:procedure) { create :procedure, groupe_instructeurs: [groupe_instructeur1, groupe_instructeur2] }
  let(:groupe_instructeur1) { create(:groupe_instructeur) }
  let(:groupe_instructeur2) { create(:groupe_instructeur) }

  describe 'GET #index' do
    subject { get :index, params: { procedure_id: procedure.id } }

    context 'when logged out' do
      it { is_expected.to have_http_status(302) }
    end

    context 'when logged in as administrateur_procedure.manager=false' do
      let(:manager) { false }
      before do
        admin.administrateurs_procedures.where(procedure:).update_all(manager:)
        sign_in(admin.user)
      end

      it { is_expected.to have_http_status(200) }

      it 'use all procedure.groupe_instructeurs' do
        expect(Archive).to receive(:for_groupe_instructeur).and_return([])
        subject
      end
    end
    context 'when logged in as administrateur_procedure.manager=true' do
      let(:manager) { true }

      before do
        admin.administrateurs_procedures.where(procedure:).update_all(manager:)
        sign_in(admin.user)
      end

      it { is_expected.to have_http_status(403) }
    end
  end

  describe 'GET #create' do
    subject { post :create, params: { procedure_id: procedure.id, month: '22-06', type: 'monthly' } }

    context 'when logged out' do
      it { is_expected.to have_http_status(302) }
    end

    context 'when logged in  in as administrateur_procedure.manager=false' do
      let(:manager) { false }

      before do
        admin.administrateurs_procedures.where(procedure:).update_all(manager:)
        sign_in(admin.user)
      end

      it 'enqueue the creation job' do
        expect { subject }.to have_enqueued_job(ArchiveCreationJob).with(procedure, an_instance_of(Archive), admin)
        expect(subject).to redirect_to(admin_procedure_archives_path(procedure))
      end
    end

    context 'when logged in  in as administrateur_procedure.manager=true' do
      let(:manager) { true }

      before do
        admin.administrateurs_procedures.where(procedure:).update_all(manager:)
        sign_in(admin.user)
      end

      it { is_expected.to have_http_status(403) }
      it 'does not enqueue the creation job' do
        expect { subject }.not_to have_enqueued_job(ArchiveCreationJob)
      end
    end
  end
end
