require 'spec_helper'
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

  let(:procedure_params) {
    {
      path: path,
      libelle: libelle,
      description: description,
      organisation: organisation,
      direction: direction,
      cadre_juridique: cadre_juridique,
      duree_conservation_dossiers_dans_ds: duree_conservation_dossiers_dans_ds,
      duree_conservation_dossiers_hors_ds: duree_conservation_dossiers_hors_ds
    }
  }

  before do
    sign_in admin
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
    let(:procedure_draft) { create :procedure_with_dossiers, administrateur: admin, published_at: nil, archived_at: nil }
    let(:procedure_published) { create :procedure_with_dossiers, administrateur: admin, aasm_state: :publiee, published_at: Time.zone.now, archived_at: nil }
    let(:procedure_archived) { create :procedure_with_dossiers, administrateur: admin, aasm_state: :archivee, published_at: nil, archived_at: Time.zone.now }

    subject { delete :destroy, params: { id: procedure.id } }

    context 'when the procedure is a draft' do
      let!(:procedure) { procedure_draft }

      it 'destroys the procedure' do
        expect { subject }.to change { Procedure.count }.by(-1)
      end

      it 'deletes associated dossiers' do
        subject
        expect(Dossier.find_by(procedure_id: procedure.id)).to be_blank
      end

      it 'redirects to the procedure drafts page' do
        subject
        expect(response).to redirect_to admin_procedures_draft_path
        expect(flash[:notice]).to be_present
      end
    end

    context 'when procedure is published' do
      let!(:procedure) { procedure_published }

      it { expect { subject }.not_to change { Procedure.count } }
      it { expect { subject }.not_to change { Dossier.count } }
      it { expect(subject.status).to eq 401 }
    end

    context 'when procedure is archived' do
      let!(:procedure) { procedure_archived }

      it { expect { subject }.not_to change { Procedure.count } }
      it { expect { subject }.not_to change { Dossier.count } }
      it { expect(subject.status).to eq 401 }
    end

    context "when administrateur does not own the procedure" do
      let(:procedure_not_owned) { create :procedure, administrateur: create(:administrateur), published_at: nil, archived_at: nil }

      subject { delete :destroy, params: { id: procedure_not_owned.id } }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end

  describe 'GET #edit' do
    let(:published_at) { nil }
    let(:procedure) { create(:procedure, administrateur: admin, published_at: published_at) }
    let(:procedure_id) { procedure.id }

    subject { get :edit, params: { id: procedure_id } }

    context 'when user is not connected' do
      before do
        sign_out admin
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

      context "when procedure doesn't exist" do
        let(:procedure_id) { bad_procedure_id }

        it { is_expected.to have_http_status(404) }
      end
    end
  end

  describe 'POST #create' do
    context 'when all attributs are filled' do
      describe 'new procedure in database' do
        subject { post :create, params: { procedure: procedure_params } }

        it { expect { subject }.to change { Procedure.count }.by(1) }
      end

      context 'when procedure is correctly save' do
        before do
          Flipflop::FeatureSet.current.test!.switch!(:new_champs_editor, true)
          post :create, params: { procedure: procedure_params }
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
        let(:gestionnaire) { admin.gestionnaire }

        before do
          post :create, params: { procedure: procedure_params }
        end

        describe "admin can also instruct the procedure as a gestionnaire" do
          subject { Procedure.last }
          it { expect(subject.gestionnaires).to include(gestionnaire) }
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
    let!(:procedure) { create(:procedure, :with_type_de_champ, :with_two_type_de_piece_justificative, administrateur: admin) }

    context 'when administrateur is not connected' do
      before do
        sign_out admin
      end

      subject { put :update, params: { id: procedure.id } }

      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'when administrateur is connected' do
      def update_procedure
        put :update, params: { id: procedure.id, procedure: procedure_params }
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
        let(:procedure) { create(:procedure_with_dossiers, :with_path, :with_type_de_champ, :with_two_type_de_piece_justificative, administrateur: admin) }
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
        let(:procedure) { create(:procedure, :with_type_de_champ, :with_two_type_de_piece_justificative, :published, administrateur: admin) }

        subject { update_procedure }

        describe 'only some properties can be updated' do
          it { expect(subject.libelle).to eq procedure_params[:libelle] }
          it { expect(subject.description).to eq procedure_params[:description] }
          it { expect(subject.organisation).to eq procedure_params[:organisation] }
          it { expect(subject.direction).to eq procedure_params[:direction] }

          it { expect(subject.for_individual).not_to eq procedure_params[:for_individual] }
          it { expect(subject.individual_with_siret).not_to eq procedure_params[:individual_with_siret] }
        end
      end
    end
  end

  describe 'PUT #publish' do
    let(:procedure) { create(:procedure, administrateur: admin) }
    let(:procedure2) { create(:procedure, :published, administrateur: admin) }
    let(:procedure3) { create(:procedure, :published) }

    context 'when admin is the owner of the procedure' do
      before do
        put :publish, params: { procedure_id: procedure.id, path: path }
        procedure.reload
        procedure2.reload
      end

      context 'procedure path does not exist' do
        let(:path) { 'new_path' }

        it 'publish the given procedure' do
          expect(procedure.publiee?).to be_truthy
          expect(procedure.path).to eq(path)
          expect(response.status).to eq 302
          expect(flash[:notice]).to have_content 'Démarche publiée'
        end
      end

      context 'procedure path exists and is owned by current administrator' do
        let(:path) { procedure2.path }

        it 'publish the given procedure' do
          expect(procedure.publiee?).to be_truthy
          expect(procedure.path).to eq(path)
          expect(response.status).to eq 302
          expect(flash[:notice]).to have_content 'Démarche publiée'
        end

        it 'archive previous procedure' do
          expect(procedure2.archivee?).to be_truthy
          expect(procedure2.path).to be_nil
        end
      end

      context 'procedure path exists and is not owned by current administrator' do
        let(:path) { procedure3.path }

        it 'does not publish the given procedure' do
          expect(procedure.publiee?).to be_falsey
          expect(procedure.path).not_to match(path)
          expect(response.status).to eq 200
        end

        it 'previous procedure remains published' do
          expect(procedure2.publiee?).to be_truthy
          expect(procedure2.archivee?).to be_falsey
          expect(procedure2.path).to match(/fake_path/)
        end
      end

      context 'procedure path is invalid' do
        let(:path) { 'Invalid Procedure Path' }

        it 'does not publish the given procedure' do
          expect(procedure.publiee?).to be_falsey
          expect(procedure.path).not_to match(path)
          expect(response).to redirect_to :admin_procedures
          expect(flash[:alert]).to have_content 'Lien de la démarche invalide'
        end
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out admin
        sign_in admin_2

        put :publish, params: { procedure_id: procedure.id, path: 'fake_path' }
        procedure.reload
      end

      it 'fails' do
        expect(response).to redirect_to :admin_procedures
        expect(flash[:alert]).to have_content 'Démarche inexistante'
      end
    end
  end

  describe 'PUT #archive' do
    let(:procedure) { create(:procedure, :published, administrateur: admin) }

    context 'when admin is the owner of the procedure' do
      before do
        put :archive, params: { procedure_id: procedure.id }
        procedure.reload
      end

      context 'when owner want archive procedure' do
        it { expect(procedure.archivee?).to be_truthy }
        it { expect(response).to redirect_to :admin_procedures }
        it { expect(flash[:notice]).to have_content 'Démarche archivée' }
      end

      context 'when owner want to re-enable procedure' do
        before do
          put :publish, params: { procedure_id: procedure.id, path: 'fake_path' }
          procedure.reload
        end

        it { expect(procedure.publiee?).to be_truthy }
        it { expect(response.status).to eq 302 }
        it { expect(flash[:notice]).to have_content 'Démarche publiée' }
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out admin
        sign_in admin_2

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
        sign_out admin
        sign_in admin_2
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
      let!(:large_archived_procedure)  { create(:procedure_with_dossiers, :archived,  dossiers_count: 2) }
      let!(:small_archived_procedure)  { create(:procedure_with_dossiers, :archived,  dossiers_count: 1) }

      it 'displays published and archived procedures' do
        expect(response_procedures).to include(large_published_procedure)
        expect(response_procedures).to include(large_archived_procedure)
      end

      it 'doesn’t display procedures without a significant number of dossiers' do
        expect(response_procedures).not_to include(small_archived_procedure)
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

  describe 'GET #path_list' do
    let!(:procedure) { create(:procedure, :published, administrateur: admin) }
    let(:admin2) { create(:administrateur) }
    let!(:procedure2) { create(:procedure, :published, administrateur: admin2) }
    let!(:procedure3) { create(:procedure, :published, administrateur: admin2) }

    subject { get :path_list }

    let(:body) { JSON.parse(response.body) }

    describe 'when no params' do
      before do
        subject
      end

      it { expect(response.status).to eq(200) }
      it { expect(body.size).to eq(3) }
      it { expect(body.first['label']).to eq(procedure.path) }
      it { expect(body.first['mine']).to be_truthy }
      it { expect(body.second['label']).to eq(procedure2.path) }
      it { expect(body.second['mine']).to be_falsy }
    end

    context 'filtered' do
      before do
        subject
      end

      subject { get :path_list, params: { request: URI.encode(procedure2.path) } }

      it { expect(response.status).to eq(200) }
      it { expect(body.size).to eq(1) }
      it { expect(body.first['label']).to eq(procedure2.path) }
      it { expect(body.first['mine']).to be_falsy }
    end

    context 'when procedure is archived' do
      let!(:procedure3) { create(:procedure, :archived, administrateur: admin2) }
      before do
        subject
      end

      it 'do not return on the json' do
        expect(body.size).to eq(2)
      end
    end
  end

  describe 'POST #transfer' do
    let!(:procedure) { create :procedure, :with_service, administrateur: admin }

    subject { post :transfer, params: { email_admin: email_admin, procedure_id: procedure.id } }

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

  describe "GET #check_availability" do
    render_views
    let(:procedure) { create(:procedure, :with_path, administrateur: admin) }
    let(:params) {
      {
        procedure: {
          path: path,
          id: procedure.id
        }
      }
    }
    let(:path) { generate(:published_path) }

    before do
      get :check_availability, params: params, format: 'js'
    end

    context 'self path' do
      let(:path) { procedure.path }

      it { expect(response.body).to include("innerHTML = ''") }
    end

    context 'available path' do
      it { expect(response.body).to include("innerHTML = ''") }
    end

    context 'my path (brouillon)' do
      let(:procedure_owned) { create(:procedure, :with_path, administrateur: admin) }
      let(:path) { procedure_owned.path }

      it {
        expect(response.body).to include('Une démarche en test existe déjà avec ce lien.')
      }
    end

    context 'my path' do
      let(:procedure_owned) { create(:procedure, :published, administrateur: admin) }
      let(:path) { procedure_owned.path }

      it {
        expect(response.body).to include('Ce lien est déjà utilisé par une de vos démarche.')
        expect(response.body).to include('Si vous voulez l’utiliser, l’ancienne démarche sera archivée')
      }
    end

    context 'unavailable path' do
      let(:procedure_not_owned) { create(:procedure, :with_path, administrateur: create(:administrateur)) }
      let(:path) { procedure_not_owned.path }

      it {
        expect(response.body).to include('Ce lien est déjà utilisé par une démarche.')
        expect(response.body).to include('Vous ne pouvez pas l’utiliser car il appartient à un autre administrateur.')
      }
    end
  end
end
