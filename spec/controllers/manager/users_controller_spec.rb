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
          expect(response).to redirect_to(edit_manager_user_path(user))
        end
      end

      describe 'with an invalid email' do
        let(:nouvel_email) { 'plop' }

        it 'does not update the user email' do
          subject

          expect(User.find_by(id: user.id).email).not_to eq(nouvel_email)
          expect(flash[:error]).to match("Le champ « Adresse éléctronique » est invalide. Saisir une adresse éléctronique valide, exemple : john.doe@exemple.fr")
        end
      end
    end

    context 'when the targeted email exists' do
      let(:targeted_user) { create(:user, email: 'email.existant@domaine.fr', password: '{My-$3cure-p4ssWord}') }
      let(:nouvel_email) { targeted_user.email }

      it 'launches the merge process' do
        expect_any_instance_of(User).to receive(:merge).with(user)

        subject

        expect(flash[:notice]).to match("Le compte « email.existant@domaine.fr » a absorbé le compte « ancien.email@domaine.fr ».")
        expect(response).to redirect_to(edit_manager_user_path(targeted_user))
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
