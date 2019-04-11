describe NewAdministrateur::TypesDeChampController, type: :controller do
  let(:admin) { create(:administrateur) }

  describe '#types_de_champs editor api' do
    let(:procedure) { create(:procedure) }

    before do
      admin.procedures << procedure
      sign_in admin
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
end
