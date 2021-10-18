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
    let(:user) { create(:user, email: 'ancien.email@domaine.fr', password: '{My-$3cure-p4ssWord}') }

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
      let(:targeted_user) { create(:user, email: 'email.existant@domaine.fr', password: '{My-$3cure-p4ssWord}') }
      let(:nouvel_email) { targeted_user.email }

      context 'and the old account has a dossier' do
        let!(:dossier) { create(:dossier, user: user) }

        it 'transfers the dossier' do
          subject

          expect(targeted_user.dossiers).to match([dossier])
        end
      end

      context 'and the old account belongs to an instructeur, expert and administrateur' do
        let!(:instructeur) { create(:instructeur, user: user) }
        let!(:expert) { create(:expert, user: user) }
        let!(:administrateur) { create(:administrateur, user: user) }

        it 'transfers instructeur account' do
          subject
          targeted_user.reload

          expect(targeted_user.instructeur).to match(instructeur)
          expect(targeted_user.expert).to match(expert)
          expect(targeted_user.administrateur).to match(administrateur)
          expect(flash[:notice]).to match("Le compte « email.existant@domaine.fr » a absorbé le compte « ancien.email@domaine.fr ».")
        end

        context 'and the targeted account owns an instructeur and expert as well' do
          let!(:targeted_instructeur) { create(:instructeur, user: targeted_user) }
          let!(:targeted_expert) { create(:expert, user: targeted_user) }
          let!(:targeted_administrateur) { create(:administrateur, user: targeted_user) }

          it 'merge the account' do
            expect_any_instance_of(Instructeur).to receive(:merge)
            expect_any_instance_of(Expert).to receive(:merge)
            expect_any_instance_of(Administrateur).to receive(:merge)
            subject
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
