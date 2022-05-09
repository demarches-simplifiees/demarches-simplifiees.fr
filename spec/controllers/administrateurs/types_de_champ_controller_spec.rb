describe Administrateurs::TypesDeChampController, type: :controller do
  let(:admin) { create(:administrateur) }

  describe '#types_de_champs editor api' do
    describe 'create' do
      let(:procedure) { create(:procedure) }

      before do
        admin.procedures << procedure
        sign_in(admin.user)
      end

      let(:type_champ) { TypeDeChamp.type_champs.fetch(:text) }

      context "create type_de_champ text" do
        before do
          post :create, params: {
            procedure_id: procedure.id,
            type_de_champ: {
              type_champ: type_champ,
              libelle: 'Nouveau champ'
            }
          }
        end

        it { expect(response).to have_http_status(:created) }
      end

      context "validate type_de_champ linked_drop_down_list" do
        let(:type_champ) { TypeDeChamp.type_champs.fetch(:linked_drop_down_list) }

        before do
          post :create, params: {
            procedure_id: procedure.id,
            type_de_champ: {
              type_champ: type_champ,
              libelle: 'Nouveau champ'
            }
          }
        end

        it { expect(response).to have_http_status(:unprocessable_entity) }
      end

      context "create type_de_champ linked_drop_down_list" do
        let(:type_champ) { TypeDeChamp.type_champs.fetch(:linked_drop_down_list) }

        before do
          post :create, params: {
            procedure_id: procedure.id,
            type_de_champ: {
              type_champ: type_champ,
              libelle: 'Nouveau champ',
              drop_down_list_value: '--value--'
            }
          }
        end

        it { expect(response).to have_http_status(:created) }
      end
    end

    describe 'destroy' do
      let(:procedure) { create(:procedure, :with_repetition_piece_justificative) }

      context 'repetition, type de champ pj' do
        before do
          admin.procedures << procedure
          sign_in(admin.user)
          delete :destroy, params: { procedure_id: procedure, id: procedure.types_de_champ.repetition.first.types_de_champ.first.stable_id }
        end
        it 'works' do
          expect(response).to have_http_status(:no_content)
        end
      end
    end
  end
end
