# frozen_string_literal: true

describe Instructeurs::BatchOperationsController, type: :controller do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, :for_individual, instructeurs: [instructeur]) }
  let!(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }

  describe '#POST create' do
    before { sign_in(instructeur.user) }

    context 'ACL' do
      subject { post :create, params: { procedure_id: create(:procedure).id } }
      before { sign_in(instructeur.user) }
      it 'fails when procedure does not belongs to instructeur' do
        expect(subject).to have_http_status(302)
      end
    end

    context 'success' do
      let(:params) do
        {
          procedure_id: procedure.id,
          batch_operation: {
            operation: BatchOperation.operations.fetch(:archiver),
            dossier_ids: [ dossier.id ]
          }
        }
      end
      subject { post :create, params: params }
      before { sign_in(instructeur.user) }
      it 'creates a batch operation for our signed in instructeur' do
        expect { subject }.to change { instructeur.batch_operations.count }.by(1)
        expect(BatchOperation.first.dossiers).to include(dossier)
      end
      it 'created a batch operation contains dossiers' do
        subject
        expect(BatchOperation.first.dossiers).to include(dossier)
      end
      it 'enqueues a BatchOperationJob' do
        expect {subject}.to have_enqueued_job(BatchOperationEnqueueAllJob).with(BatchOperation.last)
      end
    end
  end
end
