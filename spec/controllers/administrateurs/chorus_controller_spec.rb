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
        let(:centre_de_coup) { '{"code":"D00C8DX004","label":"Aumôniers+protestant","ville":null,"code_postal":null,"description":"Aumoniers+protestants"}' }
        let(:domaine_fonctionnel) { '{"code":"0105-05-01","label":"Formation+des+élites+et+cadres+de+sécurité+et+de+défense","description":null,"code_programme":"105"}' }
        let(:referentiel_de_programmation) { '{"code":"010101010101","label":"DOTATIONS+CARPA+AJ+ET+AUTRES+INTERVENTIONS","description":null,"code_programme":"101"}' }
        let(:chorus_configuration_params) do
          {
            centre_de_coup:, domaine_fonctionnel:, referentiel_de_programmation:
          }
        end

        it { is_expected.to redirect_to(admin_procedure_path(procedure)) }
        it 'updates params' do
          subject
          expect(flash[:notice]).to eq("La configuration Chorus a été mise à jour et prend immédiatement effet pour les nouveaux dossiers.")
          procedure.reload
          expect(procedure.chorus_configuration.centre_de_coup).to eq(JSON.parse(centre_de_coup))
          expect(procedure.chorus_configuration.domaine_fonctionnel).to eq(JSON.parse(domaine_fonctionnel))
          expect(procedure.chorus_configuration.referentiel_de_programmation).to eq(JSON.parse(referentiel_de_programmation))
        end
      end
    end
  end
end
