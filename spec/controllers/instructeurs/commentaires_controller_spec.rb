# frozen_string_literal: true
describe Instructeurs::CommentairesController, type: :controller do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, :for_individual, instructeurs: [instructeur]) }
  let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }

  before { sign_in(instructeur.user) }

  describe 'destroy' do
    let(:commentaire) { create(:commentaire, instructeur: instructeur)}
    subject { delete :destroy, params: { dossier_id: dossier.id, procedure_id: procedure.id, id: commentaire.id } }
    it 'redirect to dossier' do
      expect(subject).to redirect_to(messagerie_instructeur_dossier_path(dossier.procedure, dossier))
    end
    it 'flash success' do
      subject
      expect(flash[:success]).to eq('Votre commentaire a bien été supprimé')
    end

    context 'when it fails' do
      let(:error) { OpenStruct.new(status: false, error_messages: "boom") }
      before do
        expect(CommentaireService).to receive(:soft_delete).and_return(error)
      end
      it 'redirect to dossier' do
        expect(subject).to redirect_to(messagerie_instructeur_dossier_path(dossier.procedure, dossier))
      end
      it 'flash success' do
        subject
        expect(flash[:error]).to eq("Votre commentaire ne peut être supprimé: #{error.error_messages}")
      end
    end
  end
end
