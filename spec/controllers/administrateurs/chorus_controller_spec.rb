describe Administrateurs::ChorusController, type: :controller do
  describe 'edit' do
    let(:user) { create(:user) }
    let(:admin) { create(:administrateur, user: create(:user)) }
    let(:procedure) { create(:procedure, administrateurs: [admin]) }
    subject { get :edit, params: { procedure_id: procedure.id } }

    context 'not signed in' do
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'signed in but not admin of procedure' do
      before { sign_in(user) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'signed as admin' do
      before { sign_in(admin.user) }
      it { is_expected.to have_http_status(200) }

      context 'rendered' do
        render_views

        it { is_expected.to have_http_status(200) }
      end
    end
  end

  describe 'update' do
    let(:user) { create(:user) }
    let(:admin) { create(:administrateur, user: create(:user)) }
    let(:procedure) { create(:procedure, administrateurs: [admin]) }
    let(:chorus_configuration_params) { {} }
    subject do
      put :update,
          params: {
            procedure_id: procedure.id,
            chorus_configuration: chorus_configuration_params
          }
    end

    context 'not signed in' do
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'signed in but not admin of procedure' do
      before { sign_in(user) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'signed as admin' do
      before { sign_in(admin.user) }

      context "valid payload" do
        let(:chorus_configuration_params) do
          {
            centre_de_coup: ChorusConfiguration.centre_de_coup_options.first,
            domaine_fonctionnel: ChorusConfiguration.domaine_fonctionnel_options.first,
            referentiel_de_programmation: ChorusConfiguration.referentiel_de_programmation_options.first
          }
        end

        it { is_expected.to redirect_to(admin_procedure_path(procedure)) }
        it 'updates params' do
          subject
          expect(flash[:notice]).to eq("La configuration Chorus a été mise à jour et prend immédiatement effet pour les nouveaux dossiers.")
          procedure.reload
          expect(procedure.chorus_configuration.centre_de_coup).to eq(ChorusConfiguration.centre_de_coup_options.first)
          expect(procedure.chorus_configuration.domaine_fonctionnel).to eq(ChorusConfiguration.domaine_fonctionnel_options.first)
          expect(procedure.chorus_configuration.referentiel_de_programmation).to eq(ChorusConfiguration.referentiel_de_programmation_options.first)
        end
      end

      context "invalid payload" do
        let(:chorus_configuration_params) do
          {
            centre_de_coup: 0
          }
        end

        it { is_expected.to have_http_status(200) }
        it 'updates params' do
          subject
          expect(flash[:notice]).to eq("Des erreurs empêchent la validation du connecteur chorus. Corrigez les erreurs")
          procedure.reload
          expect(procedure.chorus_configuration.centre_de_coup).to eq(nil)
        end
      end
    end
  end
end
