require 'spec_helper'

describe Users::DossiersController, type: :controller do
  let(:user) { create(:user) }

  let(:procedure) { create(:procedure, :published) }
  let(:procedure_id) { procedure.id }
  let(:dossier) { create(:dossier, user: user, procedure: procedure) }
  let(:dossier_id) { dossier.id }
  let(:siret_not_found) { 999_999_999_999 }

  let(:rna_status) { 404 }
  let(:rna_body) { '' }

  let(:user) { create :user }

  let(:exercices_status) { 200 }
  let(:exercices_body) { File.read('spec/support/files/exercices.json') }

  let(:siren) { '440117620' }
  let(:siret) { '44011762001530' }
  let(:siret_with_whitespaces) { '440 1176 2001 530' }
  let(:bad_siret) { 1 }

  describe 'GET #show' do
    before do
      sign_in dossier.user
    end
    it 'returns http success with dossier_id valid' do
      get :show, params: {id: dossier_id}
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers liste dossier si mauvais dossier ID' do
      get :show, params: {id: siret_not_found}
      expect(response).to redirect_to root_path
    end

    describe 'before_action authorized_routes?' do
      context 'when dossier does not have a valid state' do
        before do
          dossier.state = 'en_instruction'
          dossier.save

          get :show, params: {id: dossier.id}
        end

        it { is_expected.to redirect_to root_path }
      end
    end
  end

  describe 'GET #new' do
    subject { get :new, params: {procedure_id: procedure_id} }

    context 'when params procedure_id is present' do
      context 'when procedure_id is valid' do
        context 'when user is logged in' do
          before do
            sign_in user
          end

          it { is_expected.to have_http_status(302) }
          it { is_expected.to redirect_to users_dossier_path(id: Dossier.last) }

          it { expect { subject }.to change(Dossier, :count).by 1 }

          describe 'save user siret' do
            context 'when user have not a saved siret' do
              context 'when siret is present on request' do
                subject { get :new, params: {procedure_id: procedure_id, siret: siret} }

                before do
                  subject
                  user.reload
                end

                it { expect(user.siret).to eq siret }
              end

              context 'when siret is not present on the request' do
                before do
                  subject
                  user.reload
                end

                it { expect(user.siret).to eq nil }
              end
            end

            context 'when user have a saved siret' do
              before do
                user.siret = '53029478400026'
                user.save
                user.reload
              end

              context 'when siret is present on request' do
                subject { get :new, params: {procedure_id: procedure_id, siret: siret} }

                before do
                  subject
                  user.reload
                end

                it { expect(user.siret).to eq siret }
              end

              context 'when siret is not present on the request' do
                before do
                  subject
                  user.reload
                end

                it { expect(user.siret).to eq '53029478400026' }
              end
            end
          end

          context 'when procedure is archived' do
            let(:procedure) { create(:procedure, archived_at: Time.now) }

            it { is_expected.to redirect_to users_dossiers_path }
          end
        end
        context 'when user is not logged' do
          it { is_expected.to have_http_status(302) }
          it { is_expected.to redirect_to new_user_session_path }
        end
      end

      context 'when procedure_id is not valid' do
        let(:procedure_id) { 0 }

        before do
          sign_in user
        end

        it { is_expected.to redirect_to users_dossiers_path }
      end

      context 'when procedure is not published' do
        let(:procedure) { create(:procedure, published_at: nil) }

        before do
          sign_in user
        end

        it { is_expected.to redirect_to users_dossiers_path }
      end
    end
  end

  describe 'GET #commencer' do
    subject { get :commencer, params: { procedure_path: procedure.path } }

    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to new_users_dossier_path(procedure_id: procedure.id) }

    context 'when procedure is archived' do
      let(:procedure) { create(:procedure, :published, archived_at: Time.now) }

      before do
        procedure.update_column :archived_at, Time.now
      end

      it { expect(subject.status).to eq 200 }
    end

    context 'when procedure is hidden' do
      let(:procedure) { create(:procedure, :published, hidden_at: DateTime.now) }

      it { expect(subject).to redirect_to(root_path) }
    end
  end

  describe 'POST #siret_informations' do
    let(:user) { create(:user) }

    before do
      stub_request(:get, "https://staging.entreprise.api.gouv.fr/v2/etablissements/#{siret_not_found}?token=#{SIADETOKEN}")
          .to_return(status: 404, body: 'fake body')

      stub_request(:get, "https://staging.entreprise.api.gouv.fr/v2/etablissements/#{siret}?token=#{SIADETOKEN}")
          .to_return(status: status_entreprise_call, body: File.read('spec/support/files/etablissement.json'))

      stub_request(:get, "https://staging.entreprise.api.gouv.fr/v2/entreprises/#{siren}?token=#{SIADETOKEN}")
          .to_return(status: status_entreprise_call, body: File.read('spec/support/files/entreprise.json'))

      stub_request(:get, "https://staging.entreprise.api.gouv.fr/v2/exercices/#{siret}?token=#{SIADETOKEN}")
          .to_return(status: exercices_status, body: exercices_body)

      stub_request(:get, "https://staging.entreprise.api.gouv.fr/v2/associations/#{siret}?token=#{SIADETOKEN}")
          .to_return(status: rna_status, body: rna_body)

      dossier
    end

    describe 'dossier attributs' do
      let(:status_entreprise_call) { 200 }
      shared_examples 'with valid siret' do
        before do
          sign_in user
        end

        subject { post :siret_informations, params: {dossier_id: dossier.id, dossier: {siret: example_siret}} }

        it 'create a dossier' do
          expect { subject }.to change { Dossier.count }.by(0)
        end

        it 'creates entreprise' do
          expect { subject }.to change { Entreprise.count }.by(1)
        end

        it 'links entreprise to dossier' do
          subject
          expect(Entreprise.last.dossier).to eq(Dossier.last)
        end

        it "links dossier to user" do
          subject
          expect(Dossier.last.user).to eq(user)
        end

        it 'creates etablissement for dossier' do
          expect { subject }.to change { Etablissement.count }.by(1)
        end

        it 'links etablissement to dossier' do
          subject
          expect(Etablissement.last.dossier).to eq(Dossier.last)
        end

        it 'links etablissement to entreprise' do
          subject
          expect(Etablissement.last.entreprise).to eq(Entreprise.last)
        end

        it 'creates exercices for dossier' do
          expect { subject }.to change { Exercice.count }.by(3)
          expect(Exercice.last.etablissement).to eq(Dossier.last.etablissement)
        end

        context 'when siret have no exercices' do
          let(:exercices_status) { 404 }
          let(:exercices_body) { '' }

          it { expect { subject }.not_to change { Exercice.count } }
        end

        it 'links procedure to dossier' do
          subject
          expect(Dossier.last.procedure).to eq(Procedure.last)
        end

        it 'state of dossier is brouillon' do
          subject
          expect(Dossier.last.state).to eq('brouillon')
        end

        describe 'Mandataires Sociaux' do
          let(:france_connect_information) { create(:france_connect_information, given_name: given_name, family_name: family_name, birthdate: birthdate, france_connect_particulier_id: '1234567') }
          let(:user) { create(:user, france_connect_information: france_connect_information) }

          before do
            subject
          end

          context 'when user is present in mandataires sociaux' do
            let(:given_name) { 'GERARD' }
            let(:family_name) { 'DEGONSE' }
            let(:birthdate) { '1947-07-03' }

            it { expect(Dossier.last.mandataire_social).to be_truthy }
          end

          context 'when user is not present in mandataires sociaux' do
            let(:given_name) { 'plop' }
            let(:family_name) { 'plip' }
            let(:birthdate) { '1965-01-27' }

            it { expect(Dossier.last.mandataire_social).to be_falsey }
          end
        end

        describe 'get rna informations' do
          context 'when siren have not rna informations' do
            let(:rna_status) { 404 }
            let(:rna_body) { '' }

            it 'not creates rna information for entreprise' do
              expect { subject }.to change { RNAInformation.count }.by(0)
            end
          end

          context 'when siren have rna informations' do
            let(:rna_status) { 200 }
            let(:rna_body) { File.read('spec/support/files/rna.json') }

            it 'creates rna information for entreprise' do
              expect { subject }.to change { RNAInformation.count }.by(1)
            end

            it 'links rna informations to entreprise' do
              subject
              expect(RNAInformation.last.entreprise).to eq(Entreprise.last)
            end
          end
        end
      end

      describe "with siret without whitespaces" do
        let(:example_siret) { siret }
        if ENV['CIRCLECI'].nil?
          it_should_behave_like "with valid siret"
        end
      end

      describe "with siret with whitespaces" do
        let(:example_siret) { siret_with_whitespaces }
        if ENV['CIRCLECI'].nil?
          it_should_behave_like "with valid siret"
        end
      end

      context 'with non existant siret' do
        before do
          sign_in user
          subject
        end

        let(:siret_not_found) { '11111111111111' }
        subject { post :siret_informations, params: {dossier_id: dossier.id, dossier: {siret: siret_not_found}} }

        it 'does not create new dossier' do
          expect { subject }.not_to change { Dossier.count }
        end

        it { expect(response.status).to eq 200 }
        it { expect(flash.alert).to eq 'Le siret est incorrect' }
        it { expect(response.to_a[2]).to be_an_instance_of ActionDispatch::Response::RackBody }
      end
    end

    context 'when REST error 400 is return' do
      let(:status_entreprise_call) { 400 }

      subject { post :siret_informations, params: {dossier_id: dossier.id, dossier: {siret: siret}} }

      before do
        sign_in user
        subject
      end

      it { expect(response.status).to eq 200 }
    end
  end

  describe 'PUT #update' do
    let(:params) { { id: dossier_id, dossier: { id: dossier_id, autorisation_donnees: autorisation_donnees, individual_attributes: individual_params } } }
    let(:individual_params) { { gender: 'M.', nom: 'Julien', prenom: 'Xavier', birthdate: birthdate } }
    let(:birthdate) { '20/01/1991' }
    subject { put :update, params: params }

    before do
      sign_in dossier.user
      subject
    end

    context 'when procedure is for individual' do
      let(:autorisation_donnees) { "1" }
      let(:procedure) { create(:procedure, :published, for_individual: true) }

      before do
        dossier.reload
      end

      it { expect(dossier.individual.gender).to eq 'M.' }
      it { expect(dossier.individual.nom).to eq 'Julien' }
      it { expect(dossier.individual.prenom).to eq 'Xavier' }
      it { expect(dossier.individual.birthdate).to eq '1991-01-20' }
      it { expect(dossier.procedure.for_individual).to eq true }

      context "and birthdate is ISO (YYYY-MM-DD) formatted" do
        let(:birthdate) { "1991-11-01" }
        before do
          dossier.reload
        end
        it { expect(dossier.individual.birthdate).to eq '1991-11-01' }
      end
    end

    context 'when Checkbox is checked' do
      let(:autorisation_donnees) { '1' }

      context 'procedure not use api carto' do
        it 'redirects to demande' do
          expect(response).to redirect_to(controller: :description, action: :show, dossier_id: dossier.id)
        end
      end

      context 'procedure use api carto' do
        let(:procedure) { create(:procedure, :with_api_carto) }

        before do
          subject
        end
        it 'redirects to carte' do
          expect(response).to redirect_to(controller: :carte, action: :show, dossier_id: dossier.id)
        end
      end

      it 'update dossier' do
        dossier.reload
        expect(dossier.autorisation_donnees).to be_truthy
      end
    end

    context 'when Checkbox is not checked' do
      let(:autorisation_donnees) { '0' }
      it 'uses flash alert to display message' do
        expect(flash[:alert]).to have_content('La validation des conditions d\'utilisation est obligatoire')
      end

      it "doesn't update dossier autorisation_donnees" do
        dossier.reload
        expect(dossier.autorisation_donnees).to be_falsy
      end

      it { is_expected.to redirect_to users_dossier_path(id: dossier.id) }
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { create(:user) }
    let!(:dossier_brouillon) { create :dossier, state: "brouillon", user: user }
    let!(:dossier_not_brouillon) { create :dossier, state: "en_construction", user: user }

    subject { delete :destroy, params: {id: dossier.id} }

    before do
      sign_in user
    end

    context 'when dossier is brouillon' do
      let(:dossier) { dossier_brouillon }

      it { expect(subject.status).to eq 302 }

      describe 'flash notice' do
        before do
          subject
        end

        it { expect(flash[:notice]).to be_present }
      end

      it 'destroy dossier is call' do
        expect_any_instance_of(Dossier).to receive(:destroy)
        subject
      end

      it { expect { subject }.to change { Dossier.count }.by(-1) }
    end

    context 'when dossier is not a brouillon' do
      let(:dossier) { dossier_not_brouillon }

      it { expect { subject }.to change { Dossier.count }.by(0) }
    end
  end

  describe 'PUT #change_siret' do
    let(:dossier) { create(:dossier, :with_entreprise, user: user, procedure: procedure) }

    subject { put :change_siret, params: {dossier_id: dossier.id} }

    before do
      sign_in user
    end

    it { expect(subject.status).to eq 200 }

    it 'function dossier.reset! is call' do
      expect_any_instance_of(Dossier).to receive(:reset!)
      subject
    end
  end

  describe 'GET #a_traiter' do
    context 'when user is connected' do
      before do
        sign_in user
      end

      it 'returns http success' do
        get :index, params: {liste: :a_traiter}
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #en_instruction' do
    context 'when user is connected' do
      before do
        sign_in user
      end

      it 'returns http success' do
        get :index, params: {liste: :en_instruction}
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #brouillon' do
    context 'when user is connected' do
      before do
        sign_in user
      end

      it 'returns http success' do
        get :index, params: {liste: :brouillon}
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #termine' do
    context 'when user is connected' do
      before do
        sign_in user
      end

      it 'returns http success' do
        get :index, params: {liste: :termine}
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #invite' do
    context 'when user is connected' do
      before do
        sign_in user
      end

      it 'returns http success' do
        get :index, params: {liste: :invite}
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #list_fake' do
    context 'when user is connected' do
      before do
        sign_in user
      end

      it 'returns http success' do
        get :index, params: {liste: :list_fake}
        expect(response).to redirect_to(users_dossiers_path)
      end
    end
  end

  describe 'Get #text_summary' do
    let!(:dossier) { create(:dossier, procedure: procedure) }

    context 'when user is connected' do
      before { sign_in user }

      context 'when the dossier exist' do
        before { get :text_summary, params: { dossier_id: dossier.id } }
        it 'returns the procedure name' do
          expect(JSON.parse(response.body)).to eq("textSummary" => "Dossier en brouillon répondant à la procédure #{procedure.libelle} gérée par l'organisme #{procedure.organisation}")
        end
      end

      context 'when the dossier does not exist' do
        before { get :text_summary, params: { dossier_id: 666 } }
        it { expect(response.code).to eq('404') }
      end
    end

    context 'when user is not connected' do
      before { get :text_summary, params: { dossier_id: dossier.id } }
      it { expect(response.code).to eq('302') }
    end
  end
end
