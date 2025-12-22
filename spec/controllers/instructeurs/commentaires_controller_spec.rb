# frozen_string_literal: true

describe Instructeurs::CommentairesController, type: :controller do
  let(:expert) { create(:expert) }
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, :for_individual, instructeurs: [instructeur]) }
  let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }

  render_views

  context 'as instructeur' do
    before { sign_in(instructeur.user) }

    describe 'destroy' do
      context 'when it works' do
        let(:commentaire) { create(:commentaire, instructeur: instructeur, dossier: dossier) }
        subject { delete :destroy, params: { dossier_id: dossier.id, procedure_id: procedure.id, id: commentaire.id, statut: 'a-suivre' }, format: :turbo_stream }

        it 'respond with OK and flash' do
          expect(subject).to have_http_status(:ok)
          expect(subject.body).to include('Message supprimé')
          expect(subject.body).to include('alert-success')
          expect(subject.body).to include('Votre message a été supprimé')
          expect(commentaire.reload).to be_discarded
          expect(commentaire.body).to be_empty
        end

        context 'when instructeur is not owner' do
          let(:commentaire) { create(:commentaire, dossier: dossier) }

          it 'does not delete the message' do
            expect(subject.body).to include('alert-danger')
            expect(commentaire.reload).not_to be_discarded
            expect(commentaire.body).not_to be_empty
          end
        end

        context 'when a correction is attached' do
          let!(:correction) { create(:dossier_correction, commentaire:, dossier:) }

          it 'removes the correction' do
            expect(subject).to have_http_status(:ok)
            expect(subject.body).to include('en construction') # update the header
            expect(subject.body).not_to include('en attente')
            expect(correction.reload).to be_resolved
          end
        end

        context 'when a message has an attachment' do
          let(:commentaire) { create(:commentaire, instructeur: instructeur, dossier: dossier) }
          let(:rib_path) { 'spec/fixtures/files/RIB.pdf' }

          before do
            commentaire.piece_jointe.attach(
              io: File.open(rib_path),
              filename: 'RIB.pdf',
              content_type: 'application/pdf',
              metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
            )
          end

          it 'removes the attachment when the message is deleted' do
            expect(subject).to have_http_status(:ok)

            commentaire.reload
            expect(commentaire).to be_discarded
            expect(commentaire.body).to be_empty
            expect(subject.body).not_to include('RIB.pdf')
          end
        end
      end

      context 'when dossier had been discarded' do
        let(:commentaire) { create(:commentaire, instructeur: instructeur, dossier: dossier, discarded_at: 2.hours.ago) }
        subject { delete :destroy, params: { dossier_id: dossier.id, procedure_id: procedure.id, id: commentaire.id, statut: 'a-suivre' }, format: :turbo_stream }

        it 'respond with OK and flash' do
          expect(subject).to have_http_status(:ok)
          expect(subject.body).to include('alert-danger')
          expect(subject.body).to include('Ce message a déjà été supprimé')
        end
      end
    end
  end

  context 'as expert' do
    before { sign_in(expert.user) }

    describe 'destroy' do
      context 'when it works' do
        let(:commentaire) { create(:commentaire, expert: expert, dossier: dossier) }
        subject { delete :destroy, params: { dossier_id: dossier.id, procedure_id: procedure.id, id: commentaire.id, statut: 'a-suivre' }, format: :turbo_stream }

        it 'respond with OK and flash' do
          expect(subject).to have_http_status(:ok)
          expect(subject.body).to include('Message supprimé')
          expect(subject.body).to include('alert-success')
          expect(subject.body).to include('Votre message a été supprimé')
        end
      end
    end
  end
end
