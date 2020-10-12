require 'uri'

describe Admin::ProceduresController, type: :controller do
  include ActiveJob::TestHelper

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

  let(:regulation_params) {
    {
      rgs_stamp: '1',
      rgpd: '1'
    }
  }

  before do
    sign_in(admin.user)
  end

  describe 'GET #published' do
    subject { get :published }

    it { expect(response.status).to eq(200) }
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
