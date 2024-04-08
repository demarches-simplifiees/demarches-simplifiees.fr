describe Administrateurs::TransitionsRulesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:administrateur, user: create(:user)) }
  let(:procedure) { create(:procedure, administrateurs: [admin], types_de_champ_public:) }
  let(:types_de_champ_public) { [] }

  describe '#edit' do
    subject { get :edit, params: { procedure_id: procedure.id } }

    context 'when user is not signed in' do
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when user is signed in but not admin of procedure' do
      before { sign_in(user) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when user is signed as admin' do
      before do
        sign_in(admin.user)
        subject
      end

      it { is_expected.to have_http_status(200) }

      context 'rendered without tdc' do
        let(:types_de_champ_public) { [] }
        render_views

        it { expect(response.body).to have_link("Ajouter un champ supportant le conditionnel") }
      end

      context 'rendered with tdc' do
        let(:types_de_champ_public) { [{ type: :yes_no }] }
        render_views

        it { expect(response.body).not_to have_link("Ajouter un champ supportant le conditionnel") }
      end
    end
  end
end
