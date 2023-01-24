describe Administrateurs::ProceduresController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:bad_procedure_id) { 100000 }

  let(:path) { 'ma-jolie-demarche' }
  let(:libelle) { 'Démarche de test' }
  let(:description) { 'Description de test' }
  let(:organisation) { 'Organisation de test' }
  let(:ministere) { create(:zone) }
  let(:cadre_juridique) { 'cadre juridique' }
  let(:duree_conservation_dossiers_dans_ds) { 3 }
  let(:monavis_embed) { nil }
  let(:lien_site_web) { 'http://mon-site.gouv.fr' }
  let(:zone) { create(:zone) }
  let(:zone_ids) { [zone.id] }
  let(:tags) { "[\"planete\",\"environnement\"]" }

  describe '#apercu', vcr: { cassette_name: 'api_geo_all' } do
    render_views

    let(:procedure) { create(:procedure, :with_all_champs) }
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    subject { get :apercu, params: { id: procedure.id } }

    before do
      sign_in(admin.user)
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear
    end

    it do
      subject
      expect(response).to have_http_status(:ok)
      expect(procedure.dossiers.visible_by_user).to be_empty
      expect(procedure.dossiers.for_procedure_preview).not_to be_empty
    end

    context 'when the draft is invalid' do
      before do
        allow_any_instance_of(ProcedureRevision).to receive(:invalid?).and_return(true)
      end

      it do
        subject
        expect(response).to redirect_to(champs_admin_procedure_path(procedure))
        expect(flash[:alert]).to be_present
      end
    end
  end

  let(:procedure_params) {
    {
      path: path,
      libelle: libelle,
      description: description,
      organisation: organisation,
      ministere: ministere,
      cadre_juridique: cadre_juridique,
      duree_conservation_dossiers_dans_ds: duree_conservation_dossiers_dans_ds,
      monavis_embed: monavis_embed,
      zone_ids: zone_ids,
      lien_site_web: lien_site_web,
      tags: tags
    }
  }

  before do
    sign_in(admin.user)
  end

  describe 'GET #index' do
    subject { get :index }

    it { expect(response.status).to eq(200) }
  end

  describe 'GET #index with sorting and pagination' do
    before do
      create(:procedure, administrateur: admin)
      admin.reload
    end

    subject {
      get :index, params: {
        'statut': 'publiees'
      }
    }

    it { expect(subject.status).to eq(200) }
  end

  describe 'GET #all' do
    let!(:draft_procedure)     { create(:procedure) }
    let!(:published_procedure) { create(:procedure_with_dossiers, :published, dossiers_count: 2) }
    let!(:closed_procedure)    { create(:procedure, :closed) }
    subject { get :all }

    it { expect(subject.status).to eq(200) }

    context 'for export' do
      subject { get :all, format: :xlsx }

      it 'exports result in xlsx' do
        allow(ProcedureDetail).to receive(:to_xlsx)
        subject
        expect(ProcedureDetail).to have_received(:to_xlsx)
      end
    end

    it 'display published or closed procedures' do
      subject
      expect(assigns(:procedures).any? { |p| p.id == published_procedure.id }).to be_truthy
      expect(assigns(:procedures).any? { |p| p.id == closed_procedure.id }).to be_truthy
    end

    it 'doesn’t display draft procedures' do
      subject
      expect(assigns(:procedures).any? { |p| p.id == draft_procedure.id }).to be_falsey
    end

    context "for specific zones" do
      let(:zone1) { create(:zone) }
      let(:zone2) { create(:zone) }
      let!(:procedure1) { create(:procedure, :published, zones: [zone1]) }
      let!(:procedure2) { create(:procedure, :published, zones: [zone1, zone2]) }

      subject { get :all, params: { zone_ids: [zone2.id] } }

      it 'display only procedures for specified zones' do
        subject
        expect(assigns(:procedures).any? { |p| p.id == procedure2.id }).to be_truthy
        expect(assigns(:procedures).any? { |p| p.id == procedure1.id }).to be_falsey
      end
    end

    context 'for specific status' do
      let!(:procedure1) { create(:procedure, :published) }
      let!(:procedure2) { create(:procedure, :closed) }

      it 'display only published procedures' do
        get :all, params: { statuses: ['publiee'] }
        expect(assigns(:procedures).any? { |p| p.id == procedure1.id }).to be_truthy
        expect(assigns(:procedures).any? { |p| p.id == procedure2.id }).to be_falsey
      end

      it 'display only closed procedures' do
        get :all, params: { statuses: ['close'] }
        expect(assigns(:procedures).any? { |p| p.id == procedure2.id }).to be_truthy
        expect(assigns(:procedures).any? { |p| p.id == procedure1.id }).to be_falsey
      end
    end

    context 'after specific date' do
      let(:after) { Date.new(2022, 06, 30) }
      let!(:procedure1) { create(:procedure, :published, published_at: after + 1.day) }
      let!(:procedure2) { create(:procedure, :published, published_at: after + 2.days) }
      let!(:procedure3) { create(:procedure, :published, published_at: after - 1.day) }

      it 'display only procedures published after specific date' do
        get :all, params: { from_publication_date: after }
        expect(assigns(:procedures).any? { |p| p.id == procedure1.id }).to be_truthy
        expect(assigns(:procedures).any? { |p| p.id == procedure2.id }).to be_truthy
        expect(assigns(:procedures).any? { |p| p.id == procedure3.id }).to be_falsey
      end
    end

    context 'with specific tag' do
      let!(:tag_procedure) { create(:procedure, :published, tags: ['environnement']) }

      it 'returns procedures with specific tag' do
        get :all, params: { tag: 'environnement' }
        expect(assigns(:procedures).any? { |p| p.id == tag_procedure.id }).to be_truthy
      end
    end

    context 'with libelle search' do
      let!(:procedure1) { create(:procedure, :published, libelle: 'Demande de subvention') }
      let!(:procedure2) { create(:procedure, :published, libelle: "Fonds d'aide public « Prime Entrepreneurs des Quartiers »") }
      let!(:procedure3) { create(:procedure, :published, libelle: "Hackaton pour entrepreneurs en résidence") }

      it 'returns procedures with specific terms in libelle' do
        get :all, params: { libelle: 'entrepreneur' }
        expect(assigns(:procedures).any? { |p| p.id == procedure2.id }).to be_truthy
        expect(assigns(:procedures).any? { |p| p.id == procedure3.id }).to be_truthy
        expect(assigns(:procedures).any? { |p| p.id == procedure1.id }).to be_falsey
      end
    end
  end

  describe 'GET #administrateurs' do
    let!(:draft_procedure)     { create(:procedure, administrateur: admin3) }
    let!(:published_procedure) { create(:procedure_with_dossiers, :published, dossiers_count: 2, administrateur: admin1) }
    let!(:antoher_published_procedure) { create(:procedure_with_dossiers, :published, dossiers_count: 2, administrateur: admin4) }
    let!(:closed_procedure) { create(:procedure, :closed, administrateur: admin2) }
    let(:admin1) { create(:administrateur, email: 'jesuis.surmene@education.gouv.fr') }
    let(:admin2) { create(:administrateur, email: 'jesuis.alecoute@social.gouv.fr') }
    let(:admin3) { create(:administrateur, email: 'gerard.lambert@interieur.gouv.fr') }
    let(:admin4) { create(:administrateur, email: 'jack.lang@culture.gouv.fr') }

    it 'displays admins of the procedures' do
      get :administrateurs
      expect(assigns(:admins)).to include(admin1)
      expect(assigns(:admins)).to include(admin2)
      expect(assigns(:admins)).to include(admin4)
      expect(assigns(:admins)).not_to include(admin3)
    end

    context 'with email search' do
      it 'returns procedures with specific terms in libelle' do
        get :administrateurs, params: { email: 'jesuis' }
        expect(assigns(:admins)).to include(admin1)
        expect(assigns(:admins)).to include(admin2)
        expect(assigns(:admins)).not_to include(admin3)
        expect(assigns(:admins)).not_to include(admin4)
      end
    end
  end

  describe 'POST #search' do
    before do
      stub_const("Administrateurs::ProceduresController::SIGNIFICANT_DOSSIERS_THRESHOLD", 2)
    end

    let(:query) { 'Procedure' }

    subject { post :search, params: { query: query }, format: :turbo_stream }
    let(:grouped_procedures) { subject; assigns(:grouped_procedures) }
    let(:response_procedures) { grouped_procedures.map { |_o, procedures| procedures }.flatten }

    describe 'selecting' do
      let!(:large_draft_procedure)     { create(:procedure_with_dossiers, dossiers_count: 2) }
      let!(:large_published_procedure) { create(:procedure_with_dossiers, :published, dossiers_count: 2) }
      let!(:large_closed_procedure)  { create(:procedure_with_dossiers, :closed,  dossiers_count: 2) }
      let!(:small_closed_procedure)  { create(:procedure_with_dossiers, :closed,  dossiers_count: 1) }

      it 'displays published and closed procedures' do
        expect(response_procedures).to include(large_published_procedure)
        expect(response_procedures).to include(large_closed_procedure)
      end

      it 'doesn’t display procedures without a significant number of dossiers' do
        expect(response_procedures).not_to include(small_closed_procedure)
      end

      it 'doesn’t display draft procedures' do
        expect(response_procedures).not_to include(large_draft_procedure)
      end
    end

    describe 'grouping' do
      let(:service_1) { create(:service, nom: 'DDT des Vosges') }
      let(:service_2) { create(:service, nom: 'DDT du Loiret') }
      let!(:procedure_with_service_1)  { create(:procedure_with_dossiers, :published, organisation: nil, service: service_1, dossiers_count: 2) }
      let!(:procedure_with_service_2)  { create(:procedure_with_dossiers, :published, organisation: nil, service: service_2, dossiers_count: 2) }
      let!(:procedure_without_service) { create(:procedure_with_dossiers, :published, organisation: 'DDT du Loiret', dossiers_count: 2) }

      it 'groups procedures with services as well as procedures with organisations' do
        expect(grouped_procedures.length).to eq 2
        expect(grouped_procedures.find { |o, _p| o == 'DDT des Vosges' }.last).to contain_exactly(procedure_with_service_1)
        expect(grouped_procedures.find { |o, _p| o == 'DDT du Loiret'  }.last).to contain_exactly(procedure_with_service_2, procedure_without_service)
      end
    end

    describe 'searching' do
      let!(:matching_procedure) { create(:procedure_with_dossiers, :published, dossiers_count: 2, libelle: 'éléctriCITE') }
      let!(:unmatching_procedure) { create(:procedure_with_dossiers, :published, dossiers_count: 2, libelle: 'temoin') }

      let(:query) { 'ELECTRIcité' }

      it 'is case insentivite and unaccented' do
        expect(response_procedures).to include(matching_procedure)
        expect(response_procedures).not_to include(unmatching_procedure)
      end
    end
  end

  describe 'GET #edit' do
    let(:published_at) { nil }
    let(:procedure) { create(:procedure, administrateur: admin, published_at: published_at) }
    let(:procedure_id) { procedure.id }

    subject { get :edit, params: { id: procedure_id } }

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

  describe 'GET #zones' do
    let(:procedure) { create(:procedure, administrateur: admin) }
    let(:procedure_id) { procedure.id }

    subject { get :zones, params: { id: procedure_id } }
    it { is_expected.to have_http_status(:success) }
  end

  describe 'POST #create' do
    context 'when all attributs are filled' do
      describe 'new procedure in database' do
        subject { post :create, params: { procedure: procedure_params } }

        it { expect { subject }.to change { Procedure.count }.by(1) }
      end

      context 'when procedure is correctly save' do
        before do
          post :create, params: { procedure: procedure_params }
        end

        describe 'procedure attributs in database' do
          subject { Procedure.last }

          it { expect(subject.libelle).to eq(libelle) }
          it { expect(subject.description).to eq(description) }
          it { expect(subject.organisation).to eq(organisation) }
          it { expect(subject.administrateurs).to eq([admin]) }
          it { expect(subject.duree_conservation_dossiers_dans_ds).to eq(duree_conservation_dossiers_dans_ds) }
          it { expect(subject.tags).to eq(["planete", "environnement"]) }
        end

        it { is_expected.to redirect_to(champs_admin_procedure_path(Procedure.last)) }
        it { expect(flash[:notice]).to be_present }
      end

      describe "procedure is saved with custom retention period" do
        let(:duree_conservation_dossiers_dans_ds) { 17 }

        before do
          stub_const("Procedure::NEW_MAX_DUREE_CONSERVATION", 18)
        end

        subject { post :create, params: { procedure: procedure_params } }

        it { expect { subject }.to change { Procedure.count }.by(1) }

        it "must save retention period and max retention period" do
          subject
          last_procedure = Procedure.last
          expect(last_procedure.duree_conservation_dossiers_dans_ds).to eq(duree_conservation_dossiers_dans_ds)
          expect(last_procedure.max_duree_conservation_dossiers_dans_ds).to eq(Procedure::NEW_MAX_DUREE_CONSERVATION)
        end
      end

      context 'when procedure is correctly saved' do
        let(:instructeur) { admin.instructeur }

        before do
          post :create, params: { procedure: procedure_params }
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
        subject { post :create, params: { procedure: procedure_params } }

        it { expect { subject }.to change { Procedure.count }.by(0) }

        describe 'no new module api carto in database' do
          it { expect { subject }.to change { ModuleAPICarto.count }.by(0) }
        end
      end

      describe 'flash message is present' do
        before do
          post :create, params: { procedure: procedure_params }
        end

        it { expect(flash[:alert]).to be_present }
      end
    end
  end

  describe 'PUT #update' do
    let!(:procedure) { create(:procedure, :with_type_de_champ, administrateur: admin, procedure_expires_when_termine_enabled: false) }

    context 'when administrateur is not connected' do
      before do
        sign_out(admin.user)
      end

      subject { put :update, params: { id: procedure.id } }

      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'when administrateur is connected' do
      def update_procedure
        put :update, params: { id: procedure.id, procedure: procedure_params.merge(procedure_expires_when_termine_enabled: true) }
        procedure.reload
      end

      context 'when all attributs are present' do
        let(:libelle) { 'Blable' }
        let(:description) { 'blabla' }
        let(:organisation) { 'plop' }
        let(:duree_conservation_dossiers_dans_ds) { 7 }
        let(:procedure_expires_when_termine_enabled) { true }

        before { update_procedure }

        describe 'procedure attributs in database' do
          subject { procedure }

          it { expect(subject.libelle).to eq(libelle) }
          it { expect(subject.description).to eq(description) }
          it { expect(subject.organisation).to eq(organisation) }
          it { expect(subject.duree_conservation_dossiers_dans_ds).to eq(duree_conservation_dossiers_dans_ds) }
          it { expect(subject.procedure_expires_when_termine_enabled).to eq(true) }
        end

        it { is_expected.to redirect_to(admin_procedure_path id: procedure.id) }
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
          it { expect(subject.for_individual).not_to eq procedure_params[:for_individual] }
        end
      end
    end
  end

  describe 'PUT #clone' do
    let(:procedure) { create(:procedure, :with_notice, :with_deliberation, administrateur: admin) }
    let(:params) { { procedure_id: procedure.id } }

    subject { put :clone, params: params }

    before do
      procedure

      response = Typhoeus::Response.new(code: 200, body: 'Hello world')
      Typhoeus.stub(/active_storage\/disk/).and_return(response)
    end

    it { expect { subject }.to change(Procedure, :count).by(1) }

    context 'when admin is the owner of the procedure' do
      before { subject }

      it 'creates a new procedure and redirect to it' do
        expect(response).to redirect_to admin_procedure_path(id: Procedure.last.id)
        expect(Procedure.last.cloned_from_library).to be_falsey
        expect(Procedure.last.notice.attached?).to be_truthy
        expect(Procedure.last.deliberation.attached?).to be_truthy
        expect(flash[:notice]).to have_content 'Démarche clonée, pensez a vérifier la Présentation et choisir le service a laquelle cette procédure est associé.'
      end

      context 'when the procedure is cloned from the library' do
        let(:params) { { procedure_id: procedure.id, from_new_from_existing: true } }

        it { expect(Procedure.last.cloned_from_library).to be(true) }
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out(admin.user)
        sign_in(admin_2.user)
        subject
      end

      it 'creates a new procedure and redirect to it' do
        expect(response).to redirect_to admin_procedure_path(id: Procedure.last.id)
        expect(flash[:notice]).to have_content 'Démarche clonée, pensez a vérifier la Présentation et choisir le service a laquelle cette procédure est associé.'
      end
    end
  end

  describe 'PUT #archive' do
    let(:procedure) { create(:procedure, :published, administrateur: admin, lien_site_web: lien_site_web) }

    context 'when the admin is an owner of the procedure without procedure replacement' do
      before do
        put :archive, params: { procedure_id: procedure.id }
        procedure.reload
      end

      it 'archives the procedure' do
        expect(procedure.close?).to be_truthy
        expect(response).to redirect_to :admin_procedures
        expect(flash[:notice]).to have_content 'Démarche close'
      end

      it 'does not have any replacement procedure' do
        expect(procedure.replaced_by_procedure).to be_nil
      end
    end

    context 'when the admin is an owner of the procedure with procedure replacement' do
      let(:new_procedure) { create(:procedure, :published, administrateur: admin, lien_site_web: lien_site_web) }
      before do
        put :archive, params: { procedure_id: procedure.id, new_procedure: new_procedure }
        procedure.reload
      end

      it 'archives the procedure' do
        expect(procedure.close?).to be_truthy
        expect(response).to redirect_to :admin_procedures
        expect(flash[:notice]).to have_content 'Démarche close'
      end

      it 'does have a replacement procedure' do
        expect(procedure.replaced_by_procedure).to eq(new_procedure)
      end
    end

    context 'when the admin is not an owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out(admin.user)
        sign_in(admin_2.user)

        put :archive, params: { procedure_id: procedure.id }
        procedure.reload
      end

      it 'displays an error message' do
        expect(response).to redirect_to :admin_procedures
        expect(flash[:alert]).to have_content 'Démarche inexistante'
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:procedure_draft)     { create(:procedure, administrateurs: [admin]) }
    let(:procedure_published) { create(:procedure, :published, administrateurs: [admin]) }
    let(:procedure_closed)    { create(:procedure, :closed, administrateurs: [admin]) }
    let(:procedure) { dossier.procedure }

    subject { delete :destroy, params: { id: procedure } }

    context 'when the procedure is a brouillon' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: procedure_draft) }

      before { subject }

      it 'deletes associated dossiers' do
        expect(procedure.dossiers.count).to eq(0)
      end

      it 'redirects to the procedure drafts page' do
        expect(response).to redirect_to admin_procedures_draft_path
        expect(flash[:notice]).to be_present
      end
    end

    context 'when procedure is published' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: procedure_published) }

      before { subject }

      it { expect(response.status).to eq 403 }

      context 'when dossier is en_construction' do
        let(:dossier) { create(:dossier, :en_construction, procedure: procedure_published) }

        it do
          expect(procedure.reload.close?).to be_truthy
          expect(procedure.discarded?).to be_truthy
          expect(dossier.reload.visible_by_administration?).to be_falsy
        end
      end

      context 'when dossier is accepte' do
        let(:dossier) { create(:dossier, :accepte, procedure: procedure_published) }

        it do
          expect(procedure.reload.close?).to be_truthy
          expect(procedure.discarded?).to be_truthy
          expect(dossier.reload.hidden_by_administration?).to be_truthy
        end
      end
    end

    context 'when procedure is closed' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: procedure_closed) }

      before { subject }

      it { expect(response.status).to eq 403 }

      context 'when dossier is en_construction' do
        let(:dossier) { create(:dossier, :en_construction, procedure: procedure_published) }

        it do
          expect(procedure.reload.discarded?).to be_truthy
          expect(dossier.reload.visible_by_administration?).to be_falsy
        end
      end

      context 'when dossier is accepte' do
        let(:dossier) { create(:dossier, :accepte, procedure: procedure_published) }

        it do
          expect(procedure.reload.discarded?).to be_truthy
          expect(dossier.reload.hidden_by_administration?).to be_truthy
        end
      end
    end

    context "when administrateur does not own the procedure" do
      let(:dossier) { create(:dossier) }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
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

      subject { patch :update_monavis, params: { id: procedure.id } }

      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'when administrateur is connected' do
      def update_monavis
        patch :update_monavis, params: { id: procedure.id, procedure: procedure_params }
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
    let(:token) { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c" }

    subject { patch :update_jeton, params: { id: procedure.id, procedure: { api_entreprise_token: token } } }

    before do
      allow_any_instance_of(APIEntreprise::PrivilegesAdapter).to receive(:valid?).and_return(token_is_valid)
      subject
    end

    context 'when jeton is valid' do
      let(:token_is_valid) { true }

      it { expect(flash.alert).to be_nil }
      it { expect(flash.notice).to eq('Le jeton a bien été mis à jour') }
      it { expect(procedure.reload.api_entreprise_token).to eq(token) }
    end

    context 'when jeton is invalid' do
      let(:token_is_valid) { false }

      it { expect(flash.alert).to eq("Mise à jour impossible : le jeton n’est pas valide") }
      it { expect(flash.notice).to be_nil }
      it { expect(procedure.reload.api_entreprise_token).not_to eq(token) }
    end

    context 'when jeton is not a jwt' do
      let(:token) { "invalid" }
      let(:token_is_valid) { true } # just to check jwt format by procedure model

      it { expect(flash.alert).to eq("Mise à jour impossible : le jeton n’est pas valide") }
      it { expect(flash.notice).to be_nil }
      it { expect(procedure.reload.api_entreprise_token).not_to eq(token) }
    end
  end

  describe 'PUT #publish' do
    let(:procedure) { create(:procedure, administrateur: admin, lien_site_web: lien_site_web) }
    let(:procedure2) { create(:procedure, :published, administrateur: admin, lien_site_web: lien_site_web) }
    let(:procedure3) { create(:procedure, :published, lien_site_web: lien_site_web) }
    let(:lien_site_web) { 'http://some.administration/' }

    context 'when admin is the owner of the procedure' do
      context 'procedure path does not exist' do
        let(:path) { 'new_path' }
        let(:lien_site_web) { 'http://mon-site.gouv.fr' }

        before do
          put :publish, params: { procedure_id: procedure.id, path: path, lien_site_web: lien_site_web }
          procedure.reload
        end

        it 'publish the given procedure' do
          expect(procedure.publiee?).to be_truthy
          expect(procedure.path).to eq(path)
          expect(procedure.lien_site_web).to eq(lien_site_web)
        end

        it 'redirects to the procedure page' do
          expect(response.status).to eq 302
          expect(response.body).to include(admin_procedure_path(procedure.id))
          expect(flash[:notice]).to have_content 'Démarche publiée'
        end
      end

      context 'procedure path exists and is owned by current administrator' do
        before do
          put :publish, params: { procedure_id: procedure.id, path: path, lien_site_web: lien_site_web }
          procedure.reload
          procedure2.reload
        end

        let(:path) { procedure2.path }
        let(:lien_site_web) { 'http://mon-site.gouv.fr' }

        it 'publish the given procedure' do
          expect(procedure.publiee?).to be_truthy
          expect(procedure.path).to eq(path)
          expect(procedure.lien_site_web).to eq(lien_site_web)
        end

        it 'depubliee previous procedure' do
          expect(procedure2.depubliee?).to be_truthy
        end

        it 'redirects to the procedures page' do
          expect(response.status).to eq 302
          expect(response.body).to include(admin_procedure_path(procedure.id))
          expect(flash[:notice]).to have_content 'Démarche publiée'
        end
      end

      context 'procedure path exists and is not owned by current administrator' do
        let(:path) { procedure3.path }
        let(:lien_site_web) { 'http://mon-site.gouv.fr' }
        it { expect { put :publish, params: { procedure_id: procedure.id, path: path, lien_site_web: lien_site_web } }.to raise_error(ActiveRecord::RecordInvalid) }
      end

      context 'procedure path is invalid' do
        let(:lien_site_web) { 'http://mon-site.gouv.fr' }
        let(:path) { 'Invalid Procedure Path' }
        it { expect { put :publish, params: { procedure_id: procedure.id, path: path, lien_site_web: lien_site_web } }.to raise_error(ActiveRecord::RecordInvalid) }
      end

      context 'procedure revision is invalid' do
        let(:path) { 'new_path' }
        let(:procedure) do
          create(:procedure,
                 administrateur: admin,
                 lien_site_web: lien_site_web,
                 types_de_champ_public: [{ type: :repetition, children: [] }])
        end

        it { expect { put :publish, params: { procedure_id: procedure.id, path: path, lien_site_web: lien_site_web } }.to raise_error(ActiveRecord::RecordInvalid) }
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }
      before do
        sign_out(admin.user)
        sign_in(admin_2.user)

        put :publish, params: { procedure_id: procedure.id, path: 'fake_path' }
        procedure.reload
      end

      it 'fails' do
        expect(response).to have_http_status(404)
      end
    end

    context 'when the admin does not provide a lien_site_web' do
      context 'procedure path is valid but lien_site_web is missing' do
        let(:path) { 'new_path2' }
        let(:lien_site_web) { nil }
        it { expect { put :publish, params: { procedure_id: procedure.id, path: path, lien_site_web: lien_site_web } }.to raise_error(ActiveRecord::RecordInvalid) }
      end
    end
  end

  describe 'POST #transfer' do
    let!(:procedure) { create :procedure, :with_service, administrateur: admin }

    before do
      post :transfer, params: { email_admin: email_admin, procedure_id: procedure.id }
      procedure.reload
    end

    subject do
      post :transfer, params: { email_admin: email_admin, procedure_id: procedure.id }
    end

    context 'when admin is unknow' do
      let(:email_admin) { 'plop' }

      it { expect(subject.status).to eq 302 }
      it { expect(response.body).to include(admin_procedure_transfert_path(procedure.id)) }
      it { expect(flash[:alert]).to be_present }
      it { expect(flash[:alert]).to eq("Envoi vers #{email_admin} impossible : cet administrateur n’existe pas") }
    end

    context 'when admin is known' do
      let!(:new_admin) { create :administrateur, email: 'new_admin@admin.com' }

      context "and its email address is correct" do
        let(:email_admin) { 'new_admin@admin.com' }

        it { expect(subject.status).to eq 302 }
        it { expect { subject }.to change(new_admin.procedures, :count).by(1) }

        it "should create a new service" do
          subject
          expect(new_admin.procedures.last.service_id).not_to eq(procedure.service_id)
        end
      end

      context 'when admin is know but its email was not downcased' do
        let(:email_admin) { "NEW_admin@adMIN.com" }

        it { expect(subject.status).to eq 302 }
        it { expect { subject }.to change(Procedure, :count).by(1) }
      end

      describe "correctly assigns the new admin" do
        let(:email_admin) { 'new_admin@admin.com' }

        before do
          subject
        end

        it { expect(Procedure.last.administrateurs).to eq [new_admin] }
      end
    end
  end

  describe 'PUT #allow_expert_review' do
    let!(:procedure) { create :procedure, :with_service, administrateur: admin }

    context 'when admin refuse to invite experts on this procedure' do
      before do
        procedure.update!(allow_expert_review: false)
        procedure.reload
      end

      it { expect(procedure.allow_expert_review).to be_falsy }
    end

    context 'when admin accept to invite experts on this procedure (true by default)' do
      it { expect(procedure.allow_expert_review).to be_truthy }
    end
  end

  describe 'PUT #restore' do
    let(:procedure) { create :procedure_with_dossiers, :with_service, :published, administrateur: admin }

    before do
      procedure.discard_and_keep_track!(admin)
    end

    context 'when the admin wants to restore a procedure' do
      before do
        put :restore, params: { id: procedure.id }
        procedure.reload
      end

      it { expect(procedure.discarded?).to be_falsy }
      it { expect(procedure.dossiers.first.hidden_by_administration_at).to be_nil }
    end
  end
end
