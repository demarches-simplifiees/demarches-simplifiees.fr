describe Gestionnaires::GroupeGestionnaireCommentairesController, type: :controller do
  let(:gestionnaire) { create(:gestionnaire).tap { _1.user.update(last_sign_in_at: Time.zone.now) } }
  let(:administrateur) { create(:administrateur) }
  let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire], administrateurs: [administrateur]) }
  let!(:commentaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur) }

  describe "yyyy#index" do
    render_views
    subject { get :index, params: { groupe_gestionnaire_id: groupe_gestionnaire.id } }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(gestionnaire.user)
        subject
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:groupe_gestionnaire).commentaire_groupe_gestionnaires.select("sender_id, sender_type, sender_email, MAX(id) as id, MAX(created_at) as created_at").group(:sender_id, :sender_type, :sender_email).order("MAX(id) DESC")).to include(commentaire)
        expect(response.body).to include(commentaire.sender_email)
      end
    end
  end

  describe "yyyy#show" do
    render_views
    subject { get :show, params: { groupe_gestionnaire_id: groupe_gestionnaire.id, id: commentaire.id } }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(gestionnaire.user)
        subject
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:groupe_gestionnaire).commentaire_groupe_gestionnaires.where(sender: administrateur)).to include(commentaire)
        expect(response.body).to include(commentaire.body)
      end
    end
  end

  describe "yyyy#create" do
    before do
      sign_in(gestionnaire.user)
      post :create,
        params: {
          id: commentaire.id,
          groupe_gestionnaire_id: groupe_gestionnaire.id,
          commentaire_groupe_gestionnaire: { body: "avant\napres" }
        }
    end

    context 'of a new commentaire' do
      it do
        expect(groupe_gestionnaire.reload.commentaire_groupe_gestionnaires.map(&:body)).to include("avant\napres")
        expect(flash.notice).to eq("Message envoyé")
      end
    end
  end

  describe "yyyy#destroy" do
    before do
      sign_in(gestionnaire.user)
    end

    def remove_commentaire(commentaire)
      delete :destroy,
        params: {
          groupe_gestionnaire_id: groupe_gestionnaire.id,
          id: commentaire_to_delete.id
        },
        format: :turbo_stream
    end

    context 'when the commentaire was created by the gestionnaire' do
      let(:commentaire_to_delete) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, gestionnaire: gestionnaire, sender: administrateur) }

      before { remove_commentaire(commentaire_to_delete) }

      it do
        expect(groupe_gestionnaire.reload.commentaire_groupe_gestionnaires.count).to eq(2)
        expect(commentaire_to_delete.reload.discarded?).to eq(true)
        expect(flash.notice).to eq("Votre message a été supprimé")
      end
    end

    context 'when the commentaire was not created by the gestionnaire' do
      let(:commentaire_to_delete) { commentaire }

      before { remove_commentaire(commentaire_to_delete) }

      it do
        expect(groupe_gestionnaire.reload.commentaire_groupe_gestionnaires.count).to eq(1)
        expect(commentaire_to_delete.reload.discarded?).to eq(false)
        expect(flash.alert).to eq("Impossible de supprimer le message, celui-ci ne vous appartient pas")
      end
    end
  end
end
