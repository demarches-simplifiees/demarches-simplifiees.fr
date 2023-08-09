describe Administrateurs::RoutingController, type: :controller do
  include Logic

  before { sign_in(procedure.administrateurs.first.user) }

  describe '#update targeted champ' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }, { type: :text, libelle: 'Un champ texte' }]) }
    let(:gi_2) { procedure.groupe_instructeurs.create(label: 'groupe 2') }
    let(:drop_down_tdc) { procedure.draft_revision.types_de_champ.first }
    let(:params) do
      {
        procedure_id: procedure.id,
        targeted_champ: champ_value(drop_down_tdc.stable_id).to_json,
        value: empty.to_json,
        groupe_instructeur_id: gi_2.id
      }
    end

    before do
      post :update, params: params, format: :turbo_stream
    end

    it do
      expect(gi_2.reload.routing_rule).to eq(ds_eq(champ_value(drop_down_tdc.stable_id), empty))
    end

    context '#update value' do
      let(:value_updated_params) { params.merge(value: constant('Lyon').to_json) }

      before do
        post :update, params: value_updated_params, format: :turbo_stream
      end

      it do
        expect(gi_2.reload.routing_rule).to eq(ds_eq(champ_value(drop_down_tdc.stable_id), constant('Lyon')))
      end

      context 'targeted champ changed' do
        let(:last_tdc) { procedure.draft_revision.types_de_champ.last }

        before do
          targeted_champ_updated_params = value_updated_params.merge(targeted_champ: champ_value(last_tdc.stable_id).to_json)
          post :update, params: targeted_champ_updated_params, format: :turbo_stream
        end

        it do
          expect(gi_2.reload.routing_rule).to eq(ds_eq(champ_value(last_tdc.stable_id), empty))
        end
      end
    end
  end
end
