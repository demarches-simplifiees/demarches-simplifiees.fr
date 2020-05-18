describe NewAdministrateur::ProceduresController, type: :controller do
  let(:admin) { create(:administrateur) }
  let!(:bad_procedure_id) { 100000 }

  let!(:path) { 'ma-jolie-demarche' }
  let!(:libelle) { 'Démarche de test' }
  let!(:description) { 'Description de test' }
  let!(:organisation) { 'Organisation de test' }
  let!(:direction) { 'Direction de test' }
  let!(:cadre_juridique) { 'cadre juridique' }
  let!(:duree_conservation_dossiers_dans_ds) { 3 }
  let!(:duree_conservation_dossiers_hors_ds) { 6 }
  let!(:monavis_embed) { nil }
  let!(:lien_site_web) { 'http://mon-site.gouv.fr' }
  let!(:base_params) { { rgpd: '1', rgs_stamp: '1' } }

  describe '#apercu' do
    let(:procedure) { create(:procedure) }

    before do
      sign_in(admin.user)
      get :apercu, params: base_params.merge({ id: procedure.id })
    end

    it { expect(response).to have_http_status(:ok) }
  end

  let(:procedure_params) {
    {
      path: path,
      libelle: libelle,
      description: description,
      organisation: organisation,
      direction: direction,
      cadre_juridique: cadre_juridique,
      duree_conservation_dossiers_dans_ds: duree_conservation_dossiers_dans_ds,
      duree_conservation_dossiers_hors_ds: duree_conservation_dossiers_hors_ds,
      monavis_embed: monavis_embed,
      lien_site_web: lien_site_web
    }
  }

  before do
    sign_in(admin.user)
  end

  describe 'GET #edit' do
    let(:published_at) { nil }
    let(:procedure) { create(:procedure, administrateur: admin, published_at: published_at) }
    let(:procedure_id) { procedure.id }

    subject { get :edit, params: base_params.merge({ id: procedure_id }) }

    context 'when user is not connected' do
      before do
        sign_out(admin.user)
      end

      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'when user is connected' do
      context 'when procedure exist' do
        let(:procedure_id) { procedure.id }
        it { is_expected.to have_http_status(:success) }
      end

      context 'when procedure is published' do
        let(:published_at) { Time.zone.now }
        it { is_expected.to have_http_status(:success) }
      end

      context 'when procedure doesn’t exist' do
        let(:procedure_id) { bad_procedure_id }

        it { is_expected.to have_http_status(404) }
      end
    end
  end

  describe 'POST #create' do
    context 'when all attributs are filled' do
      describe 'new procedure in database' do
        subject { post :create, params: base_params.merge({ procedure: procedure_params }) }

        it { expect { subject }.to change { Procedure.count }.by(1) }
      end

      context 'when procedure is correctly save' do
        before do
          post :create, params: base_params.merge({ procedure: procedure_params })
        end

        describe 'procedure attributs in database' do
          subject { Procedure.last }

          it { expect(subject.libelle).to eq(libelle) }
          it { expect(subject.description).to eq(description) }
          it { expect(subject.organisation).to eq(organisation) }
          it { expect(subject.direction).to eq(direction) }
          it { expect(subject.administrateurs).to eq([admin]) }
          it { expect(subject.duree_conservation_dossiers_dans_ds).to eq(duree_conservation_dossiers_dans_ds) }
          it { expect(subject.duree_conservation_dossiers_hors_ds).to eq(duree_conservation_dossiers_hors_ds) }
        end

        it { is_expected.to redirect_to(champs_procedure_path(Procedure.last)) }
        it { expect(flash[:notice]).to be_present }
      end

      context 'when procedure is correctly saved' do
        let(:instructeur) { admin.instructeur }

        before do
          post :create, params: base_params.merge({ procedure: procedure_params })
        end

        describe "admin can also instruct the procedure as a instructeur" do
          subject { Procedure.last }
          it { expect(subject.defaut_groupe_instructeur.instructeurs).to include(instructeur) }
        end
      end
    end

    context 'when many attributs are not valid' do
      let(:libelle) { '' }
      let(:description) { '' }

      describe 'no new procedure in database' do
        subject { post :create, params: base_params.merge({ procedure: procedure_params }) }

        it { expect { subject }.to change { Procedure.count }.by(0) }

        describe 'no new module api carto in database' do
          it { expect { subject }.to change { ModuleAPICarto.count }.by(0) }
        end
      end

      describe 'flash message is present' do
        before do
          post :create, params: base_params.merge({ procedure: procedure_params })
        end

        it { expect(flash[:alert]).to be_present }
      end
    end
  end

  describe 'PUT #update' do
    let!(:procedure) { create(:procedure, :with_type_de_champ, administrateur: admin) }

    context 'when administrateur is not connected' do
      before do
        sign_out(admin.user)
      end

      subject { put :update, params: base_params.merge({ id: procedure.id }) }

      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'when administrateur is connected' do
      def update_procedure
        put :update, params: base_params.merge({ id: procedure.id, procedure: procedure_params })
        procedure.reload
      end

      context 'when all attributs are present' do
        let(:libelle) { 'Blable' }
        let(:description) { 'blabla' }
        let(:organisation) { 'plop' }
        let(:direction) { 'plap' }
        let(:duree_conservation_dossiers_dans_ds) { 7 }
        let(:duree_conservation_dossiers_hors_ds) { 5 }

        before { update_procedure }

        describe 'procedure attributs in database' do
          subject { procedure }

          it { expect(subject.libelle).to eq(libelle) }
          it { expect(subject.description).to eq(description) }
          it { expect(subject.organisation).to eq(organisation) }
          it { expect(subject.direction).to eq(direction) }
          it { expect(subject.duree_conservation_dossiers_dans_ds).to eq(duree_conservation_dossiers_dans_ds) }
          it { expect(subject.duree_conservation_dossiers_hors_ds).to eq(duree_conservation_dossiers_hors_ds) }
        end

        it { is_expected.to redirect_to(edit_admin_procedure_path id: procedure.id) }
        it { expect(flash[:notice]).to be_present }
      end

      context 'when many attributs are not valid' do
        before { update_procedure }
        let(:libelle) { '' }
        let(:description) { '' }

        describe 'flash message is present' do
          it { expect(flash[:alert]).to be_present }
        end
      end

      context 'when procedure is brouillon' do
        let(:procedure) { create(:procedure_with_dossiers, :with_path, :with_type_de_champ, administrateur: admin) }
        let!(:dossiers_count) { procedure.dossiers.count }

        describe 'dossiers are dropped' do
          subject { update_procedure }

          it {
            expect(dossiers_count).to eq(1)
            expect(subject.dossiers.count).to eq(0)
          }
        end
      end

      context 'when procedure is published' do
        let(:procedure) { create(:procedure, :with_type_de_champ, :published, administrateur: admin) }

        subject { update_procedure }

        describe 'only some properties can be updated' do
          it { expect(subject.libelle).to eq procedure_params[:libelle] }
          it { expect(subject.description).to eq procedure_params[:description] }
          it { expect(subject.organisation).to eq procedure_params[:organisation] }
          it { expect(subject.direction).to eq procedure_params[:direction] }

          it { expect(subject.for_individual).not_to eq procedure_params[:for_individual] }
        end
      end
    end
  end

  describe 'PATCH #monavis' do
    let!(:procedure) { create(:procedure, administrateur: admin) }
    let(:procedure_params) {
      {
        monavis_embed: monavis_embed
      }
    }

    context 'when administrateur is not connected' do
      before do
        sign_out(admin.user)
      end

      subject { patch :update_monavis, params: base_params.merge({ id: procedure.id }) }

      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'when administrateur is connected' do
      def update_monavis
        patch :update_monavis, params: base_params.merge({ id: procedure.id, procedure: procedure_params })
        procedure.reload
      end
      let(:monavis_embed) {
        <<-MSG
        <a href="https://monavis.numerique.gouv.fr/Demarches/123?&view-mode=formulaire-avis&nd_mode=en-ligne-enti%C3%A8rement&nd_source=button&key=cd4a872d475e4045666057f">
          <img src="https://monavis.numerique.gouv.fr/monavis-static/bouton-blanc.png" alt="Je donne mon avis" title="Je donne mon avis sur cette démarche" />
        </a>
        MSG
      }

      context 'when all attributes are present' do
        render_views

        before { update_monavis }

        context 'when the embed code is valid' do
          describe 'the monavis field is updated' do
            subject { procedure }

            it { expect(subject.monavis_embed).to eq(monavis_embed) }
          end

          it { expect(flash[:notice]).to be_present }
          it { expect(response.body).to include "MonAvis" }
        end

        context 'when the embed code is not valid' do
          let(:monavis_embed) { 'invalid embed code' }

          describe 'the monavis field is not updated' do
            subject { procedure }

            it { expect(subject.monavis_embed).to eq(nil) }
          end

          it { expect(flash[:alert]).to be_present }
          it { expect(response.body).to include "MonAvis" }
        end
      end

      context 'when procedure is published' do
        let(:procedure) { create(:procedure, :published, administrateur: admin) }

        subject { update_monavis }

        describe 'the monavis field is not updated' do
          it { expect(subject.monavis_embed).to eq monavis_embed }
        end
      end
    end
  end

  describe 'GET #jeton' do
    let(:procedure) { create(:procedure, administrateur: admin) }

    subject { get :jeton, params: { id: procedure.id } }

    it { is_expected.to have_http_status(:success) }
  end

  describe 'PATCH #jeton' do
    let(:procedure) { create(:procedure, administrateur: admin) }

    it "update api_entreprise_token" do
      patch :update_jeton, params: { id: procedure.id, procedure: { api_entreprise_token: 'ceci-est-un-jeton' } }
      expect(procedure.reload.api_entreprise_token).to eq('ceci-est-un-jeton')
    end
  end
end
