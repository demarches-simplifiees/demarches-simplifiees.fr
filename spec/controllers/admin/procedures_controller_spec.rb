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
  let(:new_type_de_champ) { {} }
  let(:types_de_champ) { {} }
  let(:new_type_de_piece_justificative) { {} }
  let(:types_de_piece_justificative) { {} }

  let(:procedure_params) {
    {
        libelle: libelle,
        description: description,
        organisation: organisation,
        direction: direction,
        lien_demarche: lien_demarche,
        use_api_carto: use_api_carto,
        new_type_de_champ: new_type_de_champ,
        types_de_champ: types_de_champ,
        new_type_de_piece_justificative: new_type_de_piece_justificative,
        types_de_piece_justificative: types_de_piece_justificative
    }
  }

  let(:two_new_type_de_champ) {
    {'0' =>
         {libelle: 'Champs de test',
          type_champs: 'number',
          description: 'Description de test',
          order_place: 1,
          '_destroy' => 'false'},
     '1' =>
         {libelle: 'Champs de test 2',
          type_champs: 'text',
          description: 'Description de test 2',
          order_place: 2,
          '_destroy' => 'false'}
    }
  }

  let(:two_new_types_de_piece_justificative) {
    {'0' =>
         {libelle: 'PJ de test',
          description: 'Description de test',
          '_destroy' => 'false'},
     '1' =>
         {libelle: 'PJ de test 2',
          description: 'Description de test 2',
          '_destroy' => 'false'}
    }
  }

  let(:two_new_type_de_champ_one_errors) {
    {'0' =>
         {libelle: '',
          type_champs: 'number',
          description: 'Description de test',
          order_place: 1,
          '_destroy' => 'false'},
     '1' =>
         {libelle: 'Champs de test 2',
          type_champs: 'text',
          description: 'Description de test 2',
          order_place: 2,
          '_destroy' => 'false'}
    }
  }

  let(:two_new_types_de_piece_justificative_one_errors) {
    {'0' =>
         {libelle: '',
          description: 'Description de test',
          '_destroy' => 'false'},
     '1' =>
         {libelle: 'Champs de test 2',
          description: 'Description de test 2',
          '_destroy' => 'false'}
    }
  }

  before do
    sign_in admin
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

    describe 'type_de_champ processing' do

      before do
        post :create, procedure: procedure_params
      end

      subject { Procedure.last }

      context 'when no type de champs is filled' do
        let(:new_type_de_champ) { {} }
        it { expect(subject.types_de_champ.size).to eq(0) }
      end

      context 'when two types de champs are filled' do
        let(:new_type_de_champ) { two_new_type_de_champ }
        it { expect(subject.types_de_champ.size).to eq(2) }

        describe ' check types de champs attributs present into database' do
          subject { TypeDeChamp.all }

          it { expect(subject[0].libelle).to eq(two_new_type_de_champ['0'][:libelle]) }
          it { expect(subject[0].type_champs).to eq(two_new_type_de_champ['0'][:type_champs]) }
          it { expect(subject[0].description).to eq(two_new_type_de_champ['0'][:description]) }
          it { expect(subject[0].order_place).to eq(two_new_type_de_champ['0'][:order_place]) }

          it { expect(subject[1].libelle).to eq(two_new_type_de_champ['1'][:libelle]) }
          it { expect(subject[1].type_champs).to eq(two_new_type_de_champ['1'][:type_champs]) }
          it { expect(subject[1].description).to eq(two_new_type_de_champ['1'][:description]) }
          it { expect(subject[1].order_place).to eq(two_new_type_de_champ['1'][:order_place]) }
        end
      end

      context 'when one of two types de champs have not a libelle' do
        let(:new_type_de_champ) { two_new_type_de_champ_one_errors }

        it { expect(subject.types_de_champ.size).to eq(1) }
      end
    end

    describe 'type_de_piece_justificative processing' do
      before do
        post :create, procedure: procedure_params
      end

      subject { Procedure.last }

      context 'when no type de piece justificative is filled' do
        let(:new_type_de_piece_justificative) { {} }
        it { expect(subject.types_de_piece_justificative.size).to eq(0) }
      end

      context 'when two types de piece justificative are filled' do
        let(:new_type_de_piece_justificative) { two_new_types_de_piece_justificative }

        it { expect(subject.types_de_piece_justificative.size).to eq(2) }

        describe ' check types de piece justificative attributs present into database' do
          subject { TypeDePieceJustificative.all }

          it { expect(subject[0].libelle).to eq(new_type_de_piece_justificative['0'][:libelle]) }
          it { expect(subject[0].description).to eq(new_type_de_piece_justificative['0'][:description]) }

          it { expect(subject[1].libelle).to eq(new_type_de_piece_justificative['1'][:libelle]) }
          it { expect(subject[1].description).to eq(new_type_de_piece_justificative['1'][:description]) }
        end
      end

      context 'when one of two types de piece justificative have not a libelle' do
        let(:new_type_de_piece_justificative) { two_new_types_de_piece_justificative_one_errors }

        it { expect(subject.types_de_piece_justificative.size).to eq(1) }
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

      describe 'type_de_champ processing' do
        subject { procedure }

        context 'when no type de champs is filled' do
          let(:new_type_de_champ) { {} }
          it { expect(subject.types_de_champ.size).to eq(1) }
        end

        context 'when two types de champs are filled' do
          let(:new_type_de_champ) { two_new_type_de_champ }
          it { expect(subject.types_de_champ.size).to eq(3) }

          describe ' check types de champs attributs added into database' do
            subject { procedure.types_de_champ }

            it { expect(subject[1].libelle).to eq(two_new_type_de_champ['0'][:libelle]) }
            it { expect(subject[1].type_champs).to eq(two_new_type_de_champ['0'][:type_champs]) }
            it { expect(subject[1].description).to eq(two_new_type_de_champ['0'][:description]) }
            it { expect(subject[1].order_place).to eq(two_new_type_de_champ['0'][:order_place]) }

            it { expect(subject[2].libelle).to eq(two_new_type_de_champ['1'][:libelle]) }
            it { expect(subject[2].type_champs).to eq(two_new_type_de_champ['1'][:type_champs]) }
            it { expect(subject[2].description).to eq(two_new_type_de_champ['1'][:description]) }
            it { expect(subject[2].order_place).to eq(two_new_type_de_champ['1'][:order_place]) }
          end
        end

        context 'when one of two types de champs have not a libelle' do
          let(:procedure) { create(:procedure) }
          let(:new_type_de_champ) { two_new_type_de_champ_one_errors }

          it { expect(subject.types_de_champ.size).to eq(1) }
        end

        context 'when user edit the filed' do
          let(:type_de_champ_id) { procedure.types_de_champ.first.id }
          let(:types_de_champ) {
            {"#{type_de_champ_id}" =>
                 {libelle: 'Champs de test editée',
                  type_champs: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  _destroy: 'false'
                 }
            }
          }

          it { expect(subject.types_de_champ.size).to eq(1) }

          describe ' check types de champs attributs updated into database' do
            subject { procedure.types_de_champ.first }

            it { expect(subject.libelle).to eq(types_de_champ["#{type_de_champ_id}"][:libelle]) }
            it { expect(subject.type_champs).to eq(types_de_champ["#{type_de_champ_id}"][:type_champs]) }
            it { expect(subject.description).to eq(types_de_champ["#{type_de_champ_id}"][:description]) }
            it { expect(subject.order_place).to eq(types_de_champ["#{type_de_champ_id}"][:order_place]) }
          end
        end

        context 'when no delete a type de champs' do
          let(:types_de_champ) {
            {"#{procedure.types_de_champ.first.id}" =>
                 {libelle: 'Champs de test editée',
                  type_champs: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  _destroy: 'false'}
            }
          }

          it { expect(subject.types_de_champ.size).to eq(1) }
        end

        context 'when delete a type de champs' do
          let(:types_de_champ) {
            {"#{procedure.types_de_champ.first.id}" =>
                 {libelle: 'Champs de test editée',
                  type_champs: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  _destroy: 'true'}
            }
          }

          it { expect(subject.types_de_champ.size).to eq(0) }
        end

        context 'when delete a type de champs present in database and a type champ not present in database' do
          let(:types_de_champ) {
            {"#{procedure.types_de_champ.first.id}" =>
                 {libelle: 'Champs de test editée',
                  type_champs: 'number',
                  description: 'Description de test editée',
                  order_place: 1,
                  _destroy: 'true'}
            }
          }

          let(:new_type_de_champ) {
            {'1' =>
                 {libelle: 'Champs de test editée',
                  type_champs: 'number',
                  description: 'Description de test editée',
                  order_place: 2,
                  _destroy: 'true'}
            }
          }

          it { expect(subject.types_de_champ.size).to eq(0) }
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
          let(:new_type_de_piece_justificative) { two_new_types_de_piece_justificative }
          it { expect(subject.types_de_piece_justificative.size).to eq(2) }

          describe ' check types de piece justificative attributs added into database' do
            subject { procedure.types_de_piece_justificative }

            it { expect(subject[0].libelle).to eq(new_type_de_piece_justificative['0'][:libelle]) }
            it { expect(subject[0].description).to eq(new_type_de_piece_justificative['0'][:description]) }

            it { expect(subject[1].libelle).to eq(new_type_de_piece_justificative['1'][:libelle]) }
            it { expect(subject[1].description).to eq(new_type_de_piece_justificative['1'][:description]) }
          end
        end

        context 'when one of two types de piece justificative have not a libelle' do
          let(:new_type_de_piece_justificative) { two_new_types_de_piece_justificative_one_errors }

          it { expect(subject.types_de_piece_justificative.size).to eq(3) }
        end

        context 'when one types de piece justificative is edit' do
          let(:types_de_piece_justificative) {
            {"#{procedure.types_de_piece_justificative.first.id}" =>
                 {libelle: 'PJ de test editée',
                  description: 'Description de test editée',
                  '_destroy' => 'false'}
            }
          }

          it { expect(subject.types_de_piece_justificative.size).to eq(2) }

          describe ' check types de piece justificative attributs updated into database' do
            subject { procedure.types_de_piece_justificative.first }

            it { expect(subject.libelle).to eq(types_de_piece_justificative["#{procedure.types_de_piece_justificative.first.id}"][:libelle]) }
            it { expect(subject.description).to eq(types_de_piece_justificative["#{procedure.types_de_piece_justificative.first.id}"][:description]) }
          end
        end

        context 'when delete a type de piece justificative' do
          let(:types_de_piece_justificative) {
            {"#{procedure.types_de_piece_justificative.first.id}" =>
                 {libelle: 'PJ de test editée',
                  description: 'Description de test editée',
                  '_destroy' => 'true'}
            }
          }

          it { expect(subject.types_de_piece_justificative.size).to eq(1) }
        end

        context 'when delete a type de piece justificative present in database and a type piece justificative not present in database' do
          let(:types_de_piece_justificative) {
            {"#{procedure.types_de_piece_justificative.first.id}" =>
                 {libelle: 'PJ de test editée',
                  description: 'Description de test editée',
                  '_destroy' => 'true'}
            }
          }

          let(:new_type_de_piece_justificative) {
            {'1' =>
                 {libelle: 'PJ de test editée',
                  description: 'Description de test editée',
                  '_destroy' => 'true'}
            }
          }

          it { expect(subject.types_de_piece_justificative.size).to eq(1) }
        end

      end
    end
  end
end
