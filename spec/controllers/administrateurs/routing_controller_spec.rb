describe Administrateurs::RoutingController, type: :controller do
  include Logic

  before { sign_in(procedure.administrateurs.first.user) }

  describe '#update' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }]) }
    let(:gi_2) { procedure.groupe_instructeurs.create(label: 'groupe 2') }
    let(:drop_down_tdc) { procedure.draft_revision.types_de_champ.first }
    let(:params) do
      {
        procedure_id: procedure.id,
        targeted_champ: drop_down_tdc.stable_id,
        value: 'Lyon',
        groupe_instructeur_id: gi_2.id
      }
    end

    before do
      sign_in(procedure.administrateurs.first.user)
      post :update, params: params, format: :turbo_stream
    end

    it do
      expect(gi_2.reload.routing_rule).to eq(ds_eq(champ_value(drop_down_tdc.stable_id), constant('Lyon')))
    end
  end
end
