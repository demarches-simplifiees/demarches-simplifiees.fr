describe Administrateurs::TypesDeChampController, type: :controller do
  let(:procedure) { create(:procedure) }

  before { sign_in(procedure.administrateurs.first.user) }

  describe '#create' do
    let(:params) { default_params }

    let(:default_params) do
      {
        procedure_id: procedure.id,
        type_de_champ: {
          type_champ: type_champ,
          libelle: 'Nouveau champ',
          private: false,
          placeholder: "custom placeholder"
        }
      }
    end

    subject { post :create, params: params, format: :turbo_stream }

    context "create type_de_champ text" do
      let(:type_champ) { TypeDeChamp.type_champs.fetch(:text) }

      it { is_expected.to have_http_status(:ok) }
    end

    context "validate type_de_champ linked_drop_down_list" do
      let(:type_champ) { TypeDeChamp.type_champs.fetch(:linked_drop_down_list) }

      it do
        is_expected.to have_http_status(:ok)
        expect(flash.alert).to eq(nil)
      end
    end

    context "create type_de_champ linked_drop_down_list" do
      let(:type_champ) { TypeDeChamp.type_champs.fetch(:linked_drop_down_list) }
      let(:params) { default_params.deep_merge(type_de_champ: { drop_down_list_value: '--value--' }) }

      it do
        is_expected.to have_http_status(:ok)
        expect(flash.alert).to eq(nil)
      end
    end
  end
end
