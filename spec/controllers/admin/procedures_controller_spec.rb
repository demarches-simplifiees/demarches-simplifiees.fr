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

  let(:types_de_champs_params) {
    {'0' =>
         {libelle: 'Champs de test',
          type: 'number',
          description: 'Description de test',
          order_place: 1},
     '1' =>
         {libelle: 'Champs de test 2',
          type: 'text',
          description: 'Description de test 2',
          order_place: 2}
    }
  }

  let(:types_de_champs_params_errors) {
    {'0' =>
         {libelle: '',
          type: 'number',
          description: 'Description de test',
          order_place: 1},
     '1' =>
         {libelle: 'Champs de test 2',
          type: 'text',
          description: 'Description de test 2',
          order_place: 2}
    }
  }

  let(:types_de_piece_justificative_params_errors) {
    {'0' =>
         {libelle: '',
          description: 'Description de test'},
     '1' =>
         {libelle: 'Champs de test 2',
          description: 'Description de test 2'}
    }
  }

  let(:types_de_piece_justificative_params) {
    {'0' =>
         {libelle: 'PJ de test',
          description: 'Description de test'},
     '1' =>
         {libelle: 'PJ de test 2',
          description: 'Description de test 2'}
    }
  }

  before do
    sign_in admin
  end

  describe 'GET #show' do
    let(:procedure) { create(:procedure, :with_type_de_champs, :with_two_type_de_piece_justificative) }
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
        end

        it { expect(subject).to redirect_to(admin_procedures_path) }

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

    describe 'type_de_champs processing' do
      before do
        post :create, procedure: procedure_params, type_de_champs: types_de_champs_params
      end

      subject { Procedure.last }

      context 'when no type de champs is filled' do
        let(:types_de_champs_params) { {} }
        it { expect(subject.types_de_champs.size).to eq(0) }
      end

      context 'when two types de champs are filled' do
        it { expect(subject.types_de_champs.size).to eq(2) }

        describe ' check types de champs attributs present into database' do
          subject { TypeDeChamps.all }

          it { expect(subject[0].libelle).to eq(types_de_champs_params['0'][:libelle]) }
          it { expect(subject[0].type_champs).to eq(types_de_champs_params['0'][:type]) }
          it { expect(subject[0].description).to eq(types_de_champs_params['0'][:description]) }
          it { expect(subject[0].order_place).to eq(types_de_champs_params['0'][:order_place]) }

          it { expect(subject[1].libelle).to eq(types_de_champs_params['1'][:libelle]) }
          it { expect(subject[1].type_champs).to eq(types_de_champs_params['1'][:type]) }
          it { expect(subject[1].description).to eq(types_de_champs_params['1'][:description]) }
          it { expect(subject[1].order_place).to eq(types_de_champs_params['1'][:order_place]) }
        end
      end

      context 'when one of two types de champs have not a libelle' do
        let(:types_de_champs_params) { types_de_champs_params_errors }

        it { expect(subject.types_de_champs.size).to eq(1) }
      end
    end

    describe 'type_de_piece_justificative processing' do
      before do
        post :create, procedure: procedure_params, type_de_piece_justificative: types_de_piece_justificative_params
      end

      subject { Procedure.last }

      context 'when no type de piece justificative is filled' do
        let(:types_de_piece_justificative_params) { {} }
        it { expect(subject.types_de_piece_justificative.size).to eq(0) }
      end

      context 'when two types de piece justificative are filled' do
        it { expect(subject.types_de_piece_justificative.size).to eq(2) }

        describe ' check types de piece justificative attributs present into database' do
          subject { TypeDePieceJustificative.all }

          it { expect(subject[0].libelle).to eq(types_de_piece_justificative_params['0'][:libelle]) }
          it { expect(subject[0].description).to eq(types_de_piece_justificative_params['0'][:description]) }

          it { expect(subject[1].libelle).to eq(types_de_piece_justificative_params['1'][:libelle]) }
          it { expect(subject[1].description).to eq(types_de_piece_justificative_params['1'][:description]) }
        end
      end

      context 'when one of two types de piece justificative have not a libelle' do
        let(:types_de_piece_justificative_params) { types_de_piece_justificative_params_errors }

        it { expect(subject.types_de_piece_justificative.size).to eq(1) }
      end
    end
  end

  describe 'PUT #update' do
    let!(:procedure) { create(:procedure, :with_type_de_champs, :with_two_type_de_piece_justificative) }

    context 'when administrateur is not connected' do
      before do
        sign_out admin
      end

      subject { put :update, id: procedure.id }

      it { expect(subject).to redirect_to new_administrateur_session_path }
    end

    context 'when administrateur is connected' do
      before do
        put :update, id: procedure.id, procedure: procedure_params, type_de_champs: types_de_champs_params, type_de_piece_justificative: types_de_piece_justificative_params
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

      describe 'type_de_champs processing' do
        subject { procedure }

        context 'when no type de champs is filled' do
          let(:types_de_champs_params) { {} }
          it { expect(subject.types_de_champs.size).to eq(1) }
        end

        context 'when two types de champs are filled' do
          it { expect(subject.types_de_champs.size).to eq(3) }

          describe ' check types de champs attributs added into database' do
            subject { procedure.types_de_champs }

            it { expect(subject[1].libelle).to eq(types_de_champs_params['0'][:libelle]) }
            it { expect(subject[1].type_champs).to eq(types_de_champs_params['0'][:type]) }
            it { expect(subject[1].description).to eq(types_de_champs_params['0'][:description]) }
            it { expect(subject[1].order_place).to eq(types_de_champs_params['0'][:order_place]) }

            it { expect(subject[2].libelle).to eq(types_de_champs_params['1'][:libelle]) }
            it { expect(subject[2].type_champs).to eq(types_de_champs_params['1'][:type]) }
            it { expect(subject[2].description).to eq(types_de_champs_params['1'][:description]) }
            it { expect(subject[2].order_place).to eq(types_de_champs_params['1'][:order_place]) }
          end
        end

        context 'when one of two types de champs have not a libelle' do
          let(:procedure) { create(:procedure) }
          let(:types_de_champs_params) { types_de_champs_params_errors }

          it { expect(subject.types_de_champs.size).to eq(1) }
        end

        context 'when user edit the filed' do
          let(:types_de_champs_params) {
            {'0' =>
                 {libelle: 'Champs de test editée',
                  type: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  id_type_de_champs: procedure.types_de_champs.first.id}
            }
          }

          it { expect(subject.types_de_champs.size).to eq(1) }

          describe ' check types de champs attributs updated into database' do
            subject { procedure.types_de_champs.first }

            it { expect(subject.libelle).to eq(types_de_champs_params['0'][:libelle]) }
            it { expect(subject.type_champs).to eq(types_de_champs_params['0'][:type]) }
            it { expect(subject.description).to eq(types_de_champs_params['0'][:description]) }
            it { expect(subject.order_place).to eq(types_de_champs_params['0'][:order_place]) }
          end
        end

        context 'when delete a type de champs' do
          let(:types_de_champs_params) {
            {'0' =>
                 {libelle: 'Champs de test editée',
                  type: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  delete: 'true',
                  id_type_de_champs: procedure.types_de_champs.first.id}
            }
          }

          it { expect(subject.types_de_champs.size).to eq(0) }
        end

        context 'when delete a type de champs present in database and a type champ not present in database' do
          let(:types_de_champs_params) {
            {'0' =>
                 {libelle: 'Champs de test editée',
                  type: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  delete: 'true',
                  id_type_de_champs: procedure.types_de_champs.first.id},
             '1' =>
                 {libelle: 'Champs de test editée',
                  type: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  delete: 'true',
                  id_type_de_champs: ''}
            }
          }

          it { expect(subject.types_de_champs.size).to eq(0) }
        end
      end

      describe 'type_de_piece_justificative processing' do
        subject { procedure }

        context 'when no type de piece justificative is filled' do
          let(:types_de_piece_justificative_params) { {} }
          it { expect(subject.types_de_piece_justificative.size).to eq(2) }
        end

        context 'when two types de piece justificative are filled' do
          let(:procedure) { create(:procedure) }
          it { expect(subject.types_de_piece_justificative.size).to eq(2) }

          describe ' check types de piece justificative attributs added into database' do
            subject { procedure.types_de_piece_justificative }

            it { expect(subject[0].libelle).to eq(types_de_piece_justificative_params['0'][:libelle]) }
            it { expect(subject[0].description).to eq(types_de_piece_justificative_params['0'][:description]) }

            it { expect(subject[1].libelle).to eq(types_de_piece_justificative_params['1'][:libelle]) }
            it { expect(subject[1].description).to eq(types_de_piece_justificative_params['1'][:description]) }
          end
        end

        context 'when one of two types de piece justificative have not a libelle' do
          let(:types_de_piece_justificative_params) { types_de_piece_justificative_params_errors }

          it { expect(subject.types_de_piece_justificative.size).to eq(3) }
        end

        context 'when one types de piece justificative is edit' do
          let(:types_de_piece_justificative_params) {
            {'0' =>
                 {libelle: 'PJ de test editée',
                  type: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  id_type_de_piece_justificative: procedure.types_de_piece_justificative.first.id}
            }
          }

          it { expect(subject.types_de_piece_justificative.size).to eq(2) }

          describe ' check types de piece justificative attributs updated into database' do
            subject { procedure.types_de_piece_justificative.first }

            it { expect(subject.libelle).to eq(types_de_piece_justificative_params['0'][:libelle]) }
            it { expect(subject.description).to eq(types_de_piece_justificative_params['0'][:description]) }
          end
        end

        context 'when delete a type de piece justificative' do
          let(:types_de_piece_justificative_params) {
            {'0' =>
                 {libelle: 'PJ de test editée',
                  type: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  delete: 'true',
                  id_type_de_piece_justificative: procedure.types_de_piece_justificative.first.id}
            }
          }

          it { expect(subject.types_de_piece_justificative.size).to eq(1) }
        end

        context 'when delete a type de piece justificative present in database and a type piece justificative not present in database' do
          let(:types_de_piece_justificative_params) {
            {'0' =>
                 {libelle: 'PJ de test editée',
                  type: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  delete: 'true',
                  id_type_de_piece_justificative: procedure.types_de_piece_justificative.first.id},
             '1' =>
                 {libelle: 'PJ de test editée',
                  type: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  delete: 'true',
                  id_type_de_piece_justificative: ''}
            }
          }

          it { expect(subject.types_de_piece_justificative.size).to eq(1) }
        end

      end
    end
  end
end
