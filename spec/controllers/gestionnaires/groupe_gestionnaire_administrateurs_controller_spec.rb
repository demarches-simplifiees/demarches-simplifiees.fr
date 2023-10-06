describe Gestionnaires::GroupeGestionnaireAdministrateursController, type: :controller do
  let(:gestionnaire) { create(:gestionnaire).tap { _1.user.update(last_sign_in_at: Time.zone.now) } }
  let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }

  before { sign_in gestionnaire.user }

  describe '#create' do
    before do
      post :create,
        params: {
          groupe_gestionnaire_id: groupe_gestionnaire.id,
          administrateur: { email: new_administrateur_email }
        },
        format: :turbo_stream
    end

    context 'of a new administrateur' do
      let(:new_administrateur_email) { 'new_administrateur@mail.com' }

      it { expect(groupe_gestionnaire.reload.administrateurs.map(&:email)).to include(new_administrateur_email) }
      it { expect(flash.notice).to eq("Les administrateurs ont bien été affectés au groupe gestionnaire") }
    end
  end

  describe '#destroy' do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:new_administrateur) { create(:administrateur) }

    before do
      groupe_gestionnaire.administrateurs << new_administrateur
    end

    def remove_administrateur(administrateur)
      delete :destroy,
        params: {
          groupe_gestionnaire_id: groupe_gestionnaire.id,
          id: administrateur.id
        },
        format: :turbo_stream
    end

    context 'when there are many administrateurs' do
      before { remove_administrateur(new_administrateur) }

      it { expect(groupe_gestionnaire.reload.administrateurs.count).to eq(0) }
      it { expect(flash.notice).to eq("L'administrateur « #{new_administrateur.email} » a été retiré du groupe gestionnaire.") }
    end
  end
end
