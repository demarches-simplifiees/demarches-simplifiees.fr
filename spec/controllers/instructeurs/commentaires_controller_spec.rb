# frozen_string_literal: true

describe Instructeurs::CommentairesController, type: :controller do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, :for_individual, instructeurs: [instructeur]) }
  let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }

  before { sign_in(instructeur.user) }

  describe 'destroy' do
    context 'when it works' do
      let(:commentaire) { create(:commentaire, instructeur: instructeur, dossier: dossier) }
      subject { delete :destroy, params: { dossier_id: dossier.id, procedure_id: procedure.id, id: commentaire.id } }

      it 'redirect to dossier' do
        expect(subject).to redirect_to(messagerie_instructeur_dossier_path(dossier.procedure, dossier))
      end
      it 'flash success' do
        subject
        expect(flash[:notice]).to eq(I18n.t('views.shared.commentaires.destroy.notice'))
      end
    end

    context 'when dossier had been discarded' do
      let(:commentaire) { create(:commentaire, instructeur: instructeur, dossier: dossier, discarded_at: 2.hours.ago) }
      subject { delete :destroy, params: { dossier_id: dossier.id, procedure_id: procedure.id, id: commentaire.id } }

      it 'redirect to dossier' do
        expect(subject).to redirect_to(messagerie_instructeur_dossier_path(dossier.procedure, dossier))
      end
      it 'flash success' do
        subject
        expect(flash[:alert]).to eq(I18n.t('views.shared.commentaires.destroy.alert_reasons.already_discarded'))
      end
    end
  end
end
