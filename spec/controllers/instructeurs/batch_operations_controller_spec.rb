# frozen_string_literal: true

describe Instructeurs::BatchOperationsController, type: :controller do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:simple_procedure, instructeurs: [instructeur]) }
  let(:dossier) { create(:dossier, :accepte, :with_individual, procedure: procedure) }
  let(:params) do
    {
      procedure_id: procedure.id,
      batch_operation: {
        operation: BatchOperation.operations.fetch(:archiver),
        dossier_ids: [dossier.id]
      }
    }
  end

  describe '#POST create' do
    before { sign_in(instructeur.user) }
    subject { post :create, params: params }

    context 'ACL' do
      let(:params) do
        { procedure_id: create(:procedure).id }
      end

      it 'fails when procedure does not belongs to instructeur' do
        expect(subject).to have_http_status(302)
      end
    end

    context 'success with valid dossier_ids' do
      it 'creates a batch operation for our signed in instructeur' do
        expect { subject }.to change { instructeur.batch_operations.count }.by(1)
      end
      it 'created a batch operation contains dossiers, instructeur, groupe_instructeur' do
        subject
        batch_operation = BatchOperation.first
        expect(batch_operation.dossiers).to include(dossier)
        expect(batch_operation.instructeur).to eq(instructeur)
        expect(batch_operation.groupe_instructeurs.to_a).to eq(instructeur.groupe_instructeurs.to_a)
      end
      it 'enqueues a BatchOperationJob' do
        expect { subject }.to have_enqueued_job(BatchOperationEnqueueAllJob).with(BatchOperation.last)
      end
    end
  end
end
