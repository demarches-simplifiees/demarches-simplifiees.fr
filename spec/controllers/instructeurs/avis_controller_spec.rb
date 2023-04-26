describe Instructeurs::AvisController, type: :controller do
  context 'with a instructeur signed in' do
    render_views

    let(:now) { Time.zone.parse('01/02/2345') }
    let(:expert) { create(:expert) }
    let(:claimant) { create(:instructeur) }
    let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: procedure) }
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let!(:avis_without_answer) { create(:avis, dossier: dossier, claimant: claimant, experts_procedure: experts_procedure) }

    before { sign_in(instructeur.user) }

    describe "#revoker" do
      let!(:avis) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure) }

      before do
        patch :revoquer, params: { procedure_id: procedure.id, id: avis.id }
      end

      it "revoke the dossier" do
        expect(flash.notice).to eq("#{avis.expert.email} ne peut plus donner son avis sur ce dossier.")
      end
    end

    describe 'remind' do
      before do
        allow(AvisMailer).to receive(:avis_invitation).and_return(double(deliver_later: nil))
      end
      context 'without question' do
        let!(:avis) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure) }

        it 'sends a reminder to the expert' do
          get :remind, params: { procedure_id: procedure.id, id: avis.id }
          expect(AvisMailer).to have_received(:avis_invitation).once.with(avis)
          expect(flash.notice).to eq("Un mail de relance a été envoyé à #{avis.expert.email}")
          expect(avis.reload.reminded_at).to be_present
        end
      end

      context 'with question' do
        let!(:avis) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure, question_label: '123') }

        it 'sends a reminder to the expert' do
          get :remind, params: { procedure_id: procedure.id, id: avis.id }
          expect(AvisMailer).to have_received(:avis_invitation).once.with(avis)
          expect(flash.notice).to eq("Un mail de relance a été envoyé à #{avis.expert.email}")
          expect(avis.reload.reminded_at).to be_present
        end
      end
    end
  end
end
