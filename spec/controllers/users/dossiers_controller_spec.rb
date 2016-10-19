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
      get :show, id: dossier_id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers liste dossier si mauvais dossier ID' do
      get :show, id: siret_not_found
      expect(response).to redirect_to root_path
    end

    describe 'before_action authorized_routes?' do
      context 'when dossier does not have a valid state' do
        before do
          dossier.state = 'validated'
          dossier.save

          get :show, id: dossier.id
        end

        it { is_expected.to redirect_to root_path }
      end
    end
  end

  describe 'GET #new' do
    subject { get :new, procedure_id: procedure_id }

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
                subject { get :new, procedure_id: procedure_id, siret: siret }

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
                subject { get :new, procedure_id: procedure_id, siret: siret }

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
            let(:procedure) { create(:procedure, archived: 'true') }

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
        let(:procedure) { create(:procedure, published: false) }

        before do
          sign_in user
        end

        it { is_expected.to redirect_to users_dossiers_path }
      end
    end
  end

  describe 'GET #commencer' do
    subject { get :commencer, procedure_path: procedure.path }

    it { expect(subject.status).to eq 302 }
    it { expect(subject).to redirect_to new_users_dossier_path(procedure_id: procedure.id) }
  end

  describe 'POST #siret_informations' do
    let(:user) { create(:user) }

    before do
      stub_request(:get, "https://api-dev.apientreprise.fr/v2/etablissements/#{siret_not_found}?token=#{SIADETOKEN}")
          .to_return(status: 404, body: 'fake body')

      stub_request(:get, "https://api-dev.apientreprise.fr/v2/etablissements/#{siret}?token=#{SIADETOKEN}")
          .to_return(status: status_entreprise_call, body: File.read('spec/support/files/etablissement.json'))

      stub_request(:get, "https://api-dev.apientreprise.fr/v2/entreprises/#{siren}?token=#{SIADETOKEN}")
          .to_return(status: status_entreprise_call, body: File.read('spec/support/files/entreprise.json'))

      stub_request(:get, "https://api-dev.apientreprise.fr/v1/etablissements/exercices/#{siret}?token=#{SIADETOKEN}")
          .to_return(status: exercices_status, body: exercices_body)

      stub_request(:get, "https://api-dev.apientreprise.fr/v1/associations/#{siret}?token=#{SIADETOKEN}")
          .to_return(status: rna_status, body: rna_body)

      dossier
    end

    describe 'dossier attributs' do
      let(:status_entreprise_call) { 200 }
      shared_examples 'with valid siret' do
        before do
          sign_in user
        end

        subject { post :siret_informations, dossier_id: dossier.id, dossier: {siret: example_siret} }

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

        it 'state of dossier is draft' do
          subject
          expect(Dossier.last.state).to eq('draft')
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
        it_should_behave_like "with valid siret"
      end

      describe "with siret with whitespaces" do
        let(:example_siret) { siret_with_whitespaces }
        it_should_behave_like "with valid siret"
      end

      context 'with non existant siret' do
        before do
          sign_in user
          subject
        end

        let(:siret_not_found) { '11111111111111' }
        subject { post :siret_informations, dossier_id: dossier.id, dossier: {siret: siret_not_found} }

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

      subject { post :siret_informations, dossier_id: dossier.id, dossier: {siret: siret} }

      before do
        sign_in user
        subject
      end

      it { expect(response.status).to eq 200 }

    end
  end

  describe 'PUT #update' do
    subject { put :update, id: dossier_id, dossier: {id: dossier_id, autorisation_donnees: autorisation_donnees} }

    before do
      sign_in dossier.user
      subject
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
        expect(flash[:alert]).to have_content('Les conditions sont obligatoires.')
      end

      it "doesn't update dossier autorisation_donnees" do
        dossier.reload
        expect(dossier.autorisation_donnees).to be_falsy
      end

      it { is_expected.to redirect_to users_dossier_path(id: dossier.id) }
    end
  end

  describe 'PUT #change_siret' do
    let(:dossier) { create(:dossier, :with_entreprise, user: user, procedure: procedure) }

    subject { put :change_siret, dossier_id: dossier.id }

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
        get :index, liste: :a_traiter
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #valides' do
    context 'when user is connected' do
      before do
        sign_in user
      end

      it 'returns http success' do
        get :index, liste: :valides
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
        get :index, liste: :en_instruction
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
        get :index, liste: :brouillon
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
        get :index, liste: :termine
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
        get :index, liste: :invite
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
        get :index, liste: :list_fake
        expect(response).to redirect_to(users_dossiers_path)
      end
    end
  end

end