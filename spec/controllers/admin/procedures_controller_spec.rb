require 'spec_helper'

describe Admin::ProceduresController, type: :controller do
  let(:admin) { create(:administrateur) }

  let(:bad_procedure_id) { 100000 }

  let(:libelle) { 'Procédure de test' }
  let(:description) { 'Description de test' }
  let(:organisation) { 'Organisation de test' }
  let(:direction) { 'Direction de test' }
  let(:lien_demarche) { 'http://localhost.com' }
  let(:use_api_carto) { '0' }
  let(:quartiers_prioritaires) { '0' }
  let(:cadastre) { '0' }
  let(:cerfa_flag) { true }

  let(:procedure_params) {
    {
        libelle: libelle,
        description: description,
        organisation: organisation,
        direction: direction,
        lien_demarche: lien_demarche,
        cerfa_flag: cerfa_flag,
        module_api_carto_attributes: {
            use_api_carto: use_api_carto,
            quartiers_prioritaires: quartiers_prioritaires,
            cadastre: cadastre
        }
    }
  }

  before do
    sign_in admin
  end

  describe 'GET #index' do
    subject { get :index }

    it { expect(response.status).to eq(200) }
  end

  describe 'GET #archived' do
    subject { get :archived }

    it { expect(response.status).to eq(200) }
  end

  describe 'GET #published' do
    subject { get :published }

    it { expect(response.status).to eq(200) }
  end

  describe 'DELETE #destroy' do
    let(:procedure_draft) { create :procedure, published_at: nil, archived: false }
    let(:procedure_published) { create :procedure, published_at: Time.now, archived: false }
    let(:procedure_archived) { create :procedure, published_at: nil, archived: true }

    subject { delete :destroy, params: {id: procedure.id} }

    context 'when procedure is draft' do
      let!(:procedure) { procedure_draft }

      describe 'tech params' do
        before do
          subject
        end

        it { expect(subject.status).to eq 302 }
        it { expect(flash[:notice]).to be_present }
      end

      it 'destroy procedure is call' do
        expect_any_instance_of(Procedure).to receive(:destroy)
        subject
      end

      it { expect { subject }.to change { Procedure.count }.by(-1) }
    end

    context 'when procedure is published' do
      let(:procedure) { procedure_published }

      it { expect(subject.status).to eq 401 }
    end

    context 'when procedure is archived' do
      let(:procedure) { procedure_published }

      it { expect(subject.status).to eq 401 }
    end
  end

  describe 'GET #edit' do
    let(:published_at) { nil }
    let(:procedure) { create(:procedure, administrateur: admin, published_at: published_at) }
    let(:procedure_id) { procedure.id }

    subject { get :edit, params: {id: procedure_id} }

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
        let(:published_at) { Time.now }
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
        subject { post :create, params: {procedure: procedure_params} }

        it { expect { subject }.to change { Procedure.count }.by(1) }
      end

      context 'when procedure is correctly save' do
        before do
          post :create, params: {procedure: procedure_params}
        end

        describe 'procedure attributs in database' do
          subject { Procedure.last }

          it { expect(subject.libelle).to eq(libelle) }
          it { expect(subject.description).to eq(description) }
          it { expect(subject.organisation).to eq(organisation) }
          it { expect(subject.direction).to eq(direction) }
          it { expect(subject.lien_demarche).to eq(lien_demarche) }
          it { expect(subject.administrateur_id).to eq(admin.id) }
        end

        describe 'procedure module api carto attributs in database' do
          let(:procedure) { Procedure.last }
          let(:use_api_carto) { '1' }
          let(:quartiers_prioritaires) { '1' }

          subject { ModuleAPICarto.last }

          it { expect(subject.procedure).to eq(procedure) }
          it { expect(subject.use_api_carto).to be_truthy }
          it { expect(subject.quartiers_prioritaires).to be_truthy }
        end

        it { is_expected.to redirect_to(admin_procedure_types_de_champ_path(procedure_id: Procedure.last.id)) }

        it { expect(flash[:notice]).to be_present }
      end
    end

    context 'when many attributs are not valid' do
      let(:libelle) { '' }
      let(:description) { '' }

      describe 'no new procedure in database' do
        subject { post :create, params: {procedure: procedure_params} }

        it { expect { subject }.to change { Procedure.count }.by(0) }

        describe 'no new module api carto in database' do
          it { expect { subject }.to change { ModuleAPICarto.count }.by(0) }
        end
      end

      describe 'flash message is present' do
        before do
          post :create, params: {procedure: procedure_params}
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

      subject { put :update, params: {id: procedure.id} }

      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'when administrateur is connected' do
      before do
        put :update, params: {id: procedure.id, procedure: procedure_params}
        procedure.reload
      end

      context 'when all attributs are present' do
        let(:libelle) { 'Blable' }
        let(:description) { 'blabla' }
        let(:organisation) { 'plop' }
        let(:direction) { 'plap' }
        let(:lien_demarche) { 'http://plip.com' }
        let(:use_api_carto) { '1' }
        let(:cadastre) { '1' }

        describe 'procedure attributs in database' do
          subject { procedure }

          it { expect(subject.libelle).to eq(libelle) }
          it { expect(subject.description).to eq(description) }
          it { expect(subject.organisation).to eq(organisation) }
          it { expect(subject.direction).to eq(direction) }
          it { expect(subject.lien_demarche).to eq(lien_demarche) }
        end

        describe 'procedure module api carto attributs in database' do
          subject { procedure.module_api_carto }

          it { expect(subject.use_api_carto).to be_truthy }
          it { expect(subject.quartiers_prioritaires).to be_falsey }
          it { expect(subject.cadastre).to be_truthy }
        end

        it { is_expected.to redirect_to(edit_admin_procedure_path id: procedure.id) }
        it { expect(flash[:notice]).to be_present }
      end

      context 'when many attributs are not valid' do
        let(:libelle) { '' }
        let(:description) { '' }

        describe 'flash message is present' do
          it { expect(flash[:alert]).to be_present }
        end

        describe 'procedure module api carto attributs in database' do
          subject { procedure.module_api_carto }

          it { expect(subject.use_api_carto).to be_falsey }
          it { expect(subject.quartiers_prioritaires).to be_falsey }
          it { expect(subject.cadastre).to be_falsey }
        end
      end

      context 'when procedure is published' do
        let!(:procedure) { create(:procedure, :with_type_de_champ, :with_two_type_de_piece_justificative, :published, administrateur: admin) }

        describe 'only some properties can be updated' do
          subject { procedure }

          it { expect(subject.libelle).to eq procedure_params[:libelle] }
          it { expect(subject.description).to eq procedure_params[:description] }
          it { expect(subject.organisation).to eq procedure_params[:organisation] }
          it { expect(subject.direction).to eq procedure_params[:direction] }

          it { expect(subject.cerfa_flag).not_to eq procedure_params[:cerfa_flag] }
          it { expect(subject.lien_demarche).not_to eq procedure_params[:lien_demarche] }
          it { expect(subject.for_individual).not_to eq procedure_params[:for_individual] }
          it { expect(subject.individual_with_siret).not_to eq procedure_params[:individual_with_siret] }
          it { expect(subject.use_api_carto).not_to eq procedure_params[:module_api_carto_attributes][:use_api_carto] }
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
        put :publish, params: {procedure_id: procedure.id, procedure_path: procedure_path}
        procedure.reload
        procedure2.reload
      end

      context 'procedure path does not exist' do
        let(:procedure_path) { 'new_path' }

        it 'publish the given procedure' do
          expect(procedure.published?).to be_truthy
          expect(procedure.path).to eq(procedure_path)
          expect(response.status).to eq 200
          expect(flash[:notice]).to have_content 'Procédure publiée'
        end
      end

      context 'procedure path exists and is owned by current administrator' do
        let(:procedure_path) { procedure2.path }

        it 'publish the given procedure' do
          expect(procedure.published?).to be_truthy
          expect(procedure.path).to eq(procedure_path)
          expect(response.status).to eq 200
          expect(flash[:notice]).to have_content 'Procédure publiée'
        end

        it 'archive previous procedure' do
          expect(procedure2.published?).to be_truthy
          expect(procedure2.archived).to be_truthy
          expect(procedure2.path).to be_nil
        end
      end

      context 'procedure path exists and is not owned by current administrator' do
        let(:procedure_path) { procedure3.path }

        it 'does not publish the given procedure' do
          expect(procedure.published?).to be_falsey
          expect(procedure.path).to be_nil
          expect(response.status).to eq 200
        end

        it 'previous procedure remains published' do
          expect(procedure2.published?).to be_truthy
          expect(procedure2.archived).to be_falsey
          expect(procedure2.path).to match(/fake_path/)
        end
      end

      context 'procedure path is invalid' do
        let(:procedure_path) { 'Invalid Procedure Path' }

        it 'does not publish the given procedure' do
          expect(procedure.published?).to be_falsey
          expect(procedure.path).to be_nil
          expect(response).to redirect_to :admin_procedures
          expect(flash[:alert]).to have_content 'Lien de la procédure invalide'
        end
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out admin
        sign_in admin_2

        put :publish, params: {procedure_id: procedure.id, procedure_path: 'fake_path'}
        procedure.reload
      end

      it 'fails' do
        expect(response).to redirect_to :admin_procedures
        expect(flash[:alert]).to have_content 'Procédure inéxistante'
      end
    end
  end

  describe 'PUT #archive' do
    let(:procedure) { create(:procedure, administrateur: admin) }

    context 'when admin is the owner of the procedure' do
      before do
        put :archive, params: {procedure_id: procedure.id}
        procedure.reload
      end

      context 'when owner want archive procedure' do
        it { expect(procedure.archived).to be_truthy }
        it { expect(response).to redirect_to :admin_procedures }
        it { expect(flash[:notice]).to have_content 'Procédure archivée' }
      end

      context 'when owner want to re-enable procedure' do
        before do
          put :publish, params: {procedure_id: procedure.id, procedure_path: 'fake_path'}
          procedure.reload
        end

        it { expect(procedure.archived).to be_falsey }
        it { expect(response.status).to eq 200 }
        it { expect(flash[:notice]).to have_content 'Procédure publiée' }
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out admin
        sign_in admin_2

        put :archive, params: {procedure_id: procedure.id}
        procedure.reload
      end

      it { expect(response).to redirect_to :admin_procedures }
      it { expect(flash[:alert]).to have_content 'Procédure inéxistante' }
    end
  end

  describe 'PUT #clone' do
    let!(:procedure) { create(:procedure, administrateur: admin) }
    subject { put :clone, params: {procedure_id: procedure.id} }

    it { expect { subject }.to change(Procedure, :count).by(1) }

    context 'when admin is the owner of the procedure' do
      before do
        subject
      end

      it 'creates a new procedure and redirect to it' do
        expect(response).to redirect_to edit_admin_procedure_path(id: Procedure.last.id)
        expect(flash[:notice]).to have_content 'Procédure clonée'
      end
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out admin
        sign_in admin_2
        subject
      end

      it { expect(response).to redirect_to :admin_procedures }
      it { expect(flash[:alert]).to have_content 'Procédure inéxistante' }
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

      subject { get :path_list, params: {request: procedure2.path} }

      it { expect(response.status).to eq(200) }
      it { expect(body.size).to eq(1) }
      it { expect(body.first['label']).to eq(procedure2.path) }
      it { expect(body.first['mine']).to be_falsy }
    end

    context 'when procedure is archived' do
      before do
        procedure3.update_attribute :archived, true
        subject
      end

      it 'do not return on the json' do
        expect(body.size).to eq(2)
      end
    end
  end

  describe 'POST transfer' do
    let!(:procedure) { create :procedure, administrateur: admin }

    subject { post :transfer, params: {email_admin: email_admin, procedure_id: procedure.id} }

    context 'when admin is unknow' do
      let(:email_admin) { 'plop' }

      it { expect(subject.status).to eq 404 }
    end

    context 'when admin is known' do
      let!(:new_admin) { create :administrateur, email: 'new_admin@admin.com' }

      context "and its email address is correct" do
        let(:email_admin) { 'new_admin@admin.com' }

        it { expect(subject.status).to eq 200 }
        it { expect { subject }.to change(Procedure, :count).by(1) }
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

        it { expect(Procedure.last.administrateur).to eq new_admin }
      end
    end
  end
end
