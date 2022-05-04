# frozen_string_literal: true

describe Instructeurs::CommentairesController, type: :controller do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, :for_individual, instructeurs: [instructeur]) }
  let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }
  render_views

  before { sign_in(instructeur.user) }

  describe 'destroy' do
    render_views

    context 'when it works' do
      let(:commentaire) { create(:commentaire, instructeur: instructeur, dossier: dossier) }
      subject { delete :destroy, params: { dossier_id: dossier.id, procedure_id: procedure.id, id: commentaire.id }, format: :turbo_stream }

      it 'respond with OK and flash' do
        expect(subject).to have_http_status(:ok)
        expect(subject.body).to include('Message supprimé')
        expect(subject.body).to include('alert-success')
        expect(subject.body).to include('Votre message a été supprimé')
      end
    end

    context 'when dossier had been discarded' do
      let(:commentaire) { create(:commentaire, instructeur: instructeur, dossier: dossier, discarded_at: 2.hours.ago) }
      subject { delete :destroy, params: { dossier_id: dossier.id, procedure_id: procedure.id, id: commentaire.id }, format: :turbo_stream }

      it 'respond with OK and flash' do
        expect(subject).to have_http_status(:ok)
        expect(subject.body).to include('alert-danger')
        expect(subject.body).to include('Ce message a déjà été supprimé')
      end
    end
  end
end
