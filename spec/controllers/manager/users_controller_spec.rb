describe Manager::UsersController, type: :controller do
  let(:super_admin) { create(:super_admin) }

  before { sign_in super_admin }

  describe '#show' do
    render_views

    let(:super_admin) { create(:super_admin) }
    let(:user) { create(:user) }

    before do
      get :show, params: { id: user.id }
    end

    it { expect(response.body).to include(user.email) }
  end

  describe '#update' do
    let(:user) { create(:user, email: 'ancien.email@domaine.fr') }

    subject { patch :update, params: { id: user.id, user: { email: nouvel_email } } }

    context 'when the targeted email does not exist' do
      describe 'with a valid email' do
        let(:nouvel_email) { 'nouvel.email@domaine.fr' }

        it 'updates the user email' do
          subject

          expect(User.find_by(id: user.id).email).to eq(nouvel_email)
        end
      end

      describe 'with an invalid email' do
        let(:nouvel_email) { 'plop' }

        it 'does not update the user email' do
          subject

          expect(User.find_by(id: user.id).email).not_to eq(nouvel_email)
          expect(flash[:error]).to match("Courriel invalide")
        end
      end
    end

    context 'when the targeted email exists' do
      let(:preexisting_user) { create(:user, email: 'email.existant@domaine.fr') }
      let(:nouvel_email) { preexisting_user.email }

      context 'and the old account has a dossier' do
        let!(:dossier) { create(:dossier, user: user) }

        it 'transfers the dossier' do
          subject

          expect(preexisting_user.dossiers).to match([dossier])
        end
      end

      context 'and the old account belongs to an instructeur and expert' do
        let!(:instructeur) { create(:instructeur, user: user) }
        let!(:expert) { create(:expert, user: user) }

        it 'transfers instructeur account' do
          subject
          preexisting_user.reload

          expect(preexisting_user.instructeur).to match(instructeur)
          expect(preexisting_user.expert).to match(expert)
          expect(flash[:notice]).to match("Le compte « email.existant@domaine.fr » a absorbé le compte « ancien.email@domaine.fr ».")
        end

        context 'and the preexisting account owns an instructeur and expert as well' do
          let!(:preexisting_instructeur) { create(:instructeur, user: preexisting_user) }
          let!(:preexisting_expert) { create(:expert, user: preexisting_user) }

          context 'and the source instructeur has some procedures and dossiers' do
            let!(:procedure) { create(:procedure, instructeurs: [instructeur]) }
            let(:dossier) { create(:dossier) }
            let(:administrateur) { create(:administrateur) }
            let!(:commentaire) { create(:commentaire, instructeur: instructeur, dossier: dossier) }
            let!(:bulk_message) { BulkMessage.create!(instructeur: instructeur, body: 'body', sent_at: Time.zone.now) }

            before do
              user.instructeur.followed_dossiers << dossier
              user.instructeur.administrateurs << administrateur
            end

            it 'transferts all the stuff' do
              subject
              preexisting_user.reload

              expect(procedure.instructeurs).to match([preexisting_user.instructeur])
              expect(preexisting_user.instructeur.followed_dossiers).to match([dossier])
              expect(preexisting_user.instructeur.administrateurs).to match([administrateur])
              expect(preexisting_user.instructeur.commentaires).to match([commentaire])
              expect(preexisting_user.instructeur.bulk_messages).to match([bulk_message])
            end
          end

          context 'and the source expert has some avis and commentaires' do
            let(:dossier) { create(:dossier) }
            let(:experts_procedure) { create(:experts_procedure, expert: user.expert, procedure: dossier.procedure) }
            let!(:avis) { create(:avis, dossier: dossier, claimant: create(:instructeur), experts_procedure: experts_procedure) }
            let!(:commentaire) { create(:commentaire, expert: expert, dossier: dossier) }

            it 'transfers the avis' do
              subject

              expect(preexisting_user.expert.avis).to match([avis])
              expect(preexisting_user.expert.commentaires).to match([commentaire])
            end
          end
        end
      end
    end
  end

  describe '#delete' do
    let(:user) { create(:user) }

    subject { delete :delete, params: { id: user.id } }

    it 'deletes the user' do
      subject

      expect(User.find_by(id: user.id)).to be_nil
    end
  end
end
