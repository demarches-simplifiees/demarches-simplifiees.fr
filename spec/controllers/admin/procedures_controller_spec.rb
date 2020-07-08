require 'uri'

describe Admin::ProceduresController, type: :controller do
  let(:admin) { create(:administrateur) }

  let(:bad_procedure_id) { 100000 }

  let(:path) { 'ma-jolie-demarche' }
  let(:libelle) { 'Démarche de test' }
  let(:description) { 'Description de test' }
  let(:organisation) { 'Organisation de test' }
  let(:direction) { 'Direction de test' }
  let(:cadre_juridique) { 'cadre juridique' }
  let(:duree_conservation_dossiers_dans_ds) { 3 }
  let(:duree_conservation_dossiers_hors_ds) { 6 }
  let(:monavis_embed) { nil }
  let(:lien_site_web) { 'http://mon-site.gouv.fr' }

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
        'procedures_smart_listing[page]': 1,
        'procedures_smart_listing[per_page]': 10,
        'procedures_smart_listing[sort][id]': 'asc'
      }
    }

    it { expect(subject.status).to eq(200) }
  end

  describe 'GET #archived' do
    subject { get :archived }

    it { expect(response.status).to eq(200) }
  end

  describe 'GET #archived with sorting and pagination' do
    subject {
      get :archived, params: {
        'procedures_smart_listing[page]': 1,
        'procedures_smart_listing[per_page]': 10,
        'procedures_smart_listing[sort][libelle]': 'asc'
      }
    }

    it { expect(subject.status).to eq(200) }
  end

  describe 'GET #published' do
    subject { get :published }

    it { expect(response.status).to eq(200) }
  end

  describe 'GET #draft with sorting and pagination' do
    subject {
      get :draft, params: {
        'procedures_smart_listing[page]': 1,
        'procedures_smart_listing[per_page]': 10,
        'procedures_smart_listing[sort][published_at]': 'asc'
      }
    }

    it { expect(subject.status).to eq(200) }
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

      it 'discard the procedure' do
        expect(procedure.reload.discarded?).to be_truthy
      end

      it 'deletes associated dossiers' do
        expect(procedure.dossiers.with_discarded.count).to eq(0)
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

        it { expect(procedure.reload.close?).to be_truthy }
        it { expect(procedure.reload.discarded?).to be_truthy }
        it { expect(dossier.reload.discarded?).to be_truthy }
      end
    end

    context 'when procedure is closed' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: procedure_closed) }

      before { subject }

      it { expect(response.status).to eq 403 }

      context 'when dossier is en_construction' do
        let(:dossier) { create(:dossier, :en_construction, procedure: procedure_published) }

        it { expect(procedure.reload.discarded?).to be_truthy }
        it { expect(dossier.reload.discarded?).to be_truthy }
      end
    end

    context "when administrateur does not own the procedure" do
      let(:dossier) { create(:dossier) }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end

  describe 'PUT #publish' do
    let(:procedure) { create(:procedure, administrateur: admin, lien_site_web: lien_site_web) }
    let(:procedure2) { create(:procedure, :published, administrateur: admin, lien_site_web: lien_site_web) }
    let(:procedure3) { create(:procedure, :published, lien_site_web: lien_site_web) }
    let(:lien_site_web) { 'http://some.administration/' }

    context 'when admin is the owner of the procedure' do
      before do
        put :publish, params: { procedure_id: procedure.id, path: path, lien_site_web: lien_site_web }, format: 'js'
        procedure.reload
        procedure2.reload
      end

      context 'procedure path does not exist' do
        let(:path) { 'new_path' }
        let(:lien_site_web) { 'http://mon-site.gouv.fr' }

        it 'publish the given procedure' do
          expect(procedure.publiee?).to be_truthy
          expect(procedure.path).to eq(path)
          expect(procedure.lien_site_web).to eq(lien_site_web)
        end

        it 'redirects to the procedures page' do
          expect(response.status).to eq 200
          expect(response.body).to include(admin_procedures_path)
          expect(flash[:notice]).to have_content 'Démarche publiée'
        end
      end

      context 'procedure path exists and is owned by current administrator' do
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
          expect(response.status).to eq 200
          expect(response.body).to include(admin_procedures_path)
          expect(flash[:notice]).to have_content 'Démarche publiée'
        end
      end

      context 'procedure path exists and is not owned by current administrator' do
        let(:path) { procedure3.path }
        let(:lien_site_web) { 'http://mon-site.gouv.fr' }

        it 'does not publish the given procedure' do
          expect(procedure.publiee?).to be_falsey
          expect(procedure.path).not_to match(path)
          expect(procedure.lien_site_web).to match(lien_site_web)
        end

        it 'previous procedure remains published' do
          expect(procedure2.publiee?).to be_truthy
          expect(procedure2.close?).to be_falsey
          expect(procedure2.path).to match(/fake_path/)
        end
      end

      context 'procedure path is invalid' do
        let(:path) { 'Invalid Procedure Path' }
        let(:lien_site_web) { 'http://mon-site.gouv.fr' }

        it 'does not publish the given procedure' do
          expect(procedure.publiee?).to be_falsey
          expect(procedure.path).not_to match(path)
          expect(procedure.lien_site_web).to match(lien_site_web)
        end
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out(admin.user)
        sign_in(admin_2.user)

        put :publish, params: { procedure_id: procedure.id, path: 'fake_path' }, format: 'js'
        procedure.reload
      end

      it 'fails' do
        expect(response).to have_http_status(404)
      end
    end

    context 'when the admin does not provide a lien_site_web' do
      before do
        put :publish, params: { procedure_id: procedure.id, path: path, lien_site_web: lien_site_web }, format: 'js'
        procedure.reload
      end
      context 'procedure path is valid but lien_site_web is missing' do
        let(:path) { 'new_path2' }
        let(:lien_site_web) { nil }

        it 'does not publish the given procedure' do
          expect(procedure.publiee?).to be_falsey
        end
      end
    end
  end

  describe 'PUT #archive' do
    let(:procedure) { create(:procedure, :published, administrateur: admin, lien_site_web: lien_site_web) }

    context 'when admin is the owner of the procedure' do
      before do
        put :archive, params: { procedure_id: procedure.id }
        procedure.reload
      end

      context 'when owner want archive procedure' do
        it { expect(procedure.close?).to be_truthy }
        it { expect(response).to redirect_to :admin_procedures }
        it { expect(flash[:notice]).to have_content 'Démarche close' }
      end

      context 'when owner want to re-enable procedure' do
        before do
          put :publish, params: { procedure_id: procedure.id, path: 'fake_path', lien_site_web: lien_site_web }
          procedure.reload
        end

        it { expect(procedure.publiee?).to be_truthy }

        it 'redirects to the procedures page' do
          expect(response.status).to eq 200
          expect(response.body).to include(admin_procedures_path)
          expect(flash[:notice]).to have_content 'Démarche publiée'
        end
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out(admin.user)
        sign_in(admin_2.user)

        put :archive, params: { procedure_id: procedure.id }
        procedure.reload
      end

      it { expect(response).to redirect_to :admin_procedures }
      it { expect(flash[:alert]).to have_content 'Démarche inexistante' }
    end
  end

  describe 'PUT #clone' do
    let!(:procedure) { create(:procedure, :with_notice, :with_deliberation, administrateur: admin) }
    let(:params) { { procedure_id: procedure.id } }
    subject { put :clone, params: params }

    before do
      response = Typhoeus::Response.new(code: 200, body: 'Hello world')
      Typhoeus.stub(/active_storage\/disk/).and_return(response)
    end

    it { expect { subject }.to change(Procedure, :count).by(1) }

    context 'when admin is the owner of the procedure' do
      before { subject }

      it 'creates a new procedure and redirect to it' do
        expect(response).to redirect_to edit_admin_procedure_path(id: Procedure.last.id)
        expect(Procedure.last.cloned_from_library).to be_falsey
        expect(Procedure.last.notice.attached?).to be_truthy
        expect(Procedure.last.deliberation.attached?).to be_truthy
        expect(flash[:notice]).to have_content 'Démarche clonée'
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
        expect(response).to redirect_to edit_admin_procedure_path(id: Procedure.last.id)
        expect(flash[:notice]).to have_content 'Démarche clonée'
      end
    end
  end

  describe 'GET #new_from_existing' do
    before do
      stub_const("Admin::ProceduresController::SIGNIFICANT_DOSSIERS_THRESHOLD", 2)
    end

    subject { get :new_from_existing }
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
  end

  describe 'POST #transfer' do
    let!(:procedure) { create :procedure, :with_service, administrateur: admin }

    subject do
      post :transfer, params: { email_admin: email_admin, procedure_id: procedure.id }, format: 'js'
    end

    context 'when admin is unknow' do
      let(:email_admin) { 'plop' }

      it { expect(subject.status).to eq 404 }
    end

    context 'when admin is known' do
      let!(:new_admin) { create :administrateur, email: 'new_admin@admin.com' }

      context "and its email address is correct" do
        let(:email_admin) { 'new_admin@admin.com' }

        it { expect(subject.status).to eq 200 }
        it { expect { subject }.to change(new_admin.procedures, :count).by(1) }

        it "should create a new service" do
          subject
          expect(new_admin.procedures.last.service_id).not_to eq(procedure.service_id)
        end
      end

      context 'when admin is know but its email was not downcased' do
        let(:email_admin) { "NEW_admin@adMIN.com" }

        it { expect(subject.status).to eq 200 }
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

  describe "DELETE #delete_deliberation" do
    context "with a demarche the admin owns" do
      let(:procedure) { create(:procedure, :with_deliberation, administrateur: admin) }

      before do
        delete :delete_deliberation, params: { id: procedure.id }
        procedure.reload
      end

      it { expect(procedure.deliberation.attached?).to eq(false) }
      it { expect(response).to redirect_to(edit_admin_procedure_path(procedure)) }
    end

    context "with a demarche the admin does not own" do
      let(:procedure) { create(:procedure, :with_deliberation) }

      before do
        delete :delete_deliberation, params: { id: procedure.id }
        procedure.reload
      end

      it { expect(response.status).to eq(404) }
    end
  end

  describe "DELETE #delete_notice" do
    context "with a demarche the admin owns" do
      let(:procedure) { create(:procedure, :with_notice, administrateur: admin) }

      before do
        delete :delete_notice, params: { id: procedure.id }
        procedure.reload
      end

      it { expect(procedure.notice.attached?).to eq(false) }
      it { expect(response).to redirect_to(edit_admin_procedure_path(procedure)) }
    end

    context "with a demarche the admin does not own" do
      let(:procedure) { create(:procedure, :with_notice) }

      before do
        delete :delete_notice, params: { id: procedure.id }
        procedure.reload
      end

      it { expect(response.status).to eq(404) }
    end
  end
end
