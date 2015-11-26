require 'spec_helper'

describe Admin::ProceduresController, type: :controller do
  let(:admin) { create(:administrateur) }

  let(:bad_procedure_id) { 100000 }

  let(:libelle) { 'Procédure de test' }
  let(:description) { 'Description de test' }
  let(:organisation) { 'Organisation de test' }
  let(:direction) { 'Direction de test' }
  let(:lien_demarche) { 'http://localhost.com' }
  let(:use_api_carto) { '1' }

  let(:procedure_params) {
    {
      libelle: libelle,
      description: description,
      organisation: organisation,
      direction: direction,
      lien_demarche: lien_demarche,
      use_api_carto: use_api_carto
    }
  }


  before do
    sign_in admin
  end

  describe 'GET #index' do
    subject { get :show }

    it { expect(response.status).to eq(200) }
  end

  describe 'GET #show' do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_two_type_de_piece_justificative) }
    let(:procedure_id) { procedure.id }

    subject { get :show, id: procedure_id }

    context 'when user is not connected' do
      before do
        sign_out admin
      end

      it { expect(subject).to redirect_to new_administrateur_session_path }
    end

    context 'when user is connected' do
      context 'when procedure exist' do
        let(:procedure_id) { procedure.id }
        it { expect(subject).to have_http_status(:success) }
      end

      context "when procedure doesn't exist" do
        let(:procedure_id) { bad_procedure_id }

        it { expect(subject).to redirect_to admin_procedures_path }
      end
    end
  end

  describe 'POST #create' do
    context 'when all attributs are filled' do
      describe 'new procedure in database' do
        subject { post :create, procedure: procedure_params }

        it { expect { subject }.to change { Procedure.count }.by(1) }
      end

      context 'when procedure is correctly save' do
        before do
          post :create, procedure: procedure_params
        end

        describe 'procedure attributs in database' do
          subject { Procedure.last }

          it { expect(subject.libelle).to eq(libelle) }
          it { expect(subject.description).to eq(description) }
          it { expect(subject.organisation).to eq(organisation) }
          it { expect(subject.direction).to eq(direction) }
          it { expect(subject.lien_demarche).to eq(lien_demarche) }
          it { expect(subject.use_api_carto).to be_truthy }
          it { expect(subject.administrateur_id).to eq(admin.id) }

        end

        it { expect(subject).to redirect_to(admin_procedure_types_de_champ_path(procedure_id:  Procedure.last.id)) }

        it { expect(flash[:notice]).to be_present }
      end
    end

    context 'when many attributs are not valid' do
      let(:libelle) { '' }
      let(:description) { '' }

      describe 'no new procedure in database' do
        subject { post :create, procedure: procedure_params }

        it { expect { subject }.to change { Procedure.count }.by(0) }
      end

      describe 'flash message is present' do
        before do
          post :create, procedure: procedure_params
        end

        it { expect(flash[:alert]).to be_present }
      end
    end
  end

  describe 'PUT #update' do
    let!(:procedure) { create(:procedure, :with_type_de_champ, :with_two_type_de_piece_justificative) }

    context 'when administrateur is not connected' do
      before do
        sign_out admin
      end

      subject { put :update, id: procedure.id }

      it { expect(subject).to redirect_to new_administrateur_session_path }
    end

    context 'when administrateur is connected' do
      before do
        put :update, id: procedure.id, procedure: procedure_params
        procedure.reload
      end

      context 'when all attributs are informated' do
        let(:libelle) { 'Blable' }
        let(:description) { 'blabla' }
        let(:organisation) { 'plop' }
        let(:direction) { 'plap' }
        let(:lien_demarche) { 'http://plip.com' }
        let(:use_api_carto) { '0' }

        describe 'procedure attributs in database' do
          subject { procedure }

          it { expect(subject.libelle).to eq(libelle) }
          it { expect(subject.description).to eq(description) }
          it { expect(subject.organisation).to eq(organisation) }
          it { expect(subject.direction).to eq(direction) }
          it { expect(subject.lien_demarche).to eq(lien_demarche) }
          it { expect(subject.use_api_carto).to be_falsey }
        end

        it { expect(subject).to redirect_to(admin_procedures_path) }
        it { expect(flash[:notice]).to be_present }
      end

      context 'when many attributs are not valid' do
        let(:libelle) { '' }
        let(:description) { '' }

        describe 'flash message is present' do
          it { expect(flash[:alert]).to be_present }
        end
      end
    end
  end

  describe 'PUT #archive' do
    let(:procedure) { create(:procedure, administrateur: admin) }



    context 'when admin is the owner of the procedure' do
      before do
        put :archive, procedure_id: procedure.id
        procedure.reload
      end

      it { expect(procedure.archived).to be_truthy }
      it { expect(response).to redirect_to :admin_procedures }
      it { expect(flash[:notice]).to have_content 'Procédure archivée' }
    end

    context 'when admin is not the owner of the procedure' do
      let(:admin_2) { create(:administrateur) }

      before do
        sign_out admin
        sign_in admin_2

        put :archive, procedure_id: procedure.id
        procedure.reload
      end

      it { expect(response).to redirect_to :admin_procedures }
      it { expect(flash[:alert]).to have_content 'Procédure inéxistante' }
    end
  end
end
