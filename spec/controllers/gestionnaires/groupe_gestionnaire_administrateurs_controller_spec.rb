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

    def destroy(administrateur)
      delete :destroy,
        params: {
          groupe_gestionnaire_id: groupe_gestionnaire.id,
          id: administrateur.id
        },
        format: :turbo_stream
    end

    context 'when administrateur is in the groupe_gestionnaire' do
      before { destroy(new_administrateur) }

      it { expect(groupe_gestionnaire.reload.administrateurs.count).to eq(0) }
      it { expect(flash.notice).to eq("L'administrateur « #{new_administrateur.email} » a été supprimé.") }
    end

    context 'when administrateur has some procedure' do
      let(:administrateur_with_procedure) { administrateurs(:default_admin) }
      let!(:procedure) { create(:procedure_with_dossiers, administrateur: administrateur_with_procedure) }
      before do
        groupe_gestionnaire.administrateurs << administrateur_with_procedure
        destroy(administrateur_with_procedure)
      end

      it { expect(groupe_gestionnaire.reload.administrateurs.count).to eq(2) }
      it { expect(flash.alert).to eq("L'administrateur « #{administrateur_with_procedure.email} » ne peut pas être supprimé du groupe gestionnaire.") }
    end

    context 'when administrateur is not in the groupe_gestionnaire' do
      let(:other_administrateur) { administrateurs(:default_admin) }
      before { destroy(other_administrateur) }

      it { expect(groupe_gestionnaire.reload.administrateurs.count).to eq(1) }
      it { expect(flash.alert).to eq("L'administrateur « #{other_administrateur.email} » n’est pas dans le groupe gestionnaire.") }
    end
  end

  describe '#remove' do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:new_administrateur) { create(:administrateur) }

    before do
      groupe_gestionnaire.administrateurs << new_administrateur
    end

    def remove(administrateur)
      delete :remove,
        params: {
          groupe_gestionnaire_id: groupe_gestionnaire.id,
          id: administrateur.id
        },
        format: :turbo_stream
    end

    context 'when administrateur is in the groupe_gestionnaire' do
      before { remove(new_administrateur) }

      it { expect(groupe_gestionnaire.reload.administrateurs.count).to eq(0) }
      it { expect(flash.notice).to eq("L'administrateur « #{new_administrateur.email} » a été retiré du groupe gestionnaire.") }
    end

    context 'when administrateur is not in the groupe_gestionnaire' do
      let(:other_administrateur) { create(:administrateur) }
      before { remove(other_administrateur) }

      it { expect(groupe_gestionnaire.reload.administrateurs.count).to eq(1) }
      it { expect(flash.alert).to eq("L'administrateur « #{other_administrateur.email} » n’est pas dans le groupe gestionnaire.") }
    end
  end
end
