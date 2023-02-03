describe Administrateurs::ConditionsController, type: :controller do
  include Logic

  let(:procedure) { create(:procedure, :with_type_de_champ, types_de_champ_count: 2) }
  let(:first_coordinate) { procedure.draft_revision.revision_types_de_champ.first }
  let(:second_tdc) { procedure.draft_revision.types_de_champ.second }

  before { sign_in(procedure.administrateurs.first.user) }

  let(:default_params) do
    {
      procedure_id: procedure.id,
      stable_id: second_tdc.stable_id
    }
  end

  describe '#update' do
    before { post :update, params: params, format: :turbo_stream }

    let(:params) { default_params.merge(type_de_champ: { condition_form: condition_form }) }

    let(:condition_form) do
      {
        rows: [
          {
            targeted_champ: champ_value(1).to_json,
            operator_name: Logic::Eq.name,
            value: '2'
          }
        ]
      }
    end

    it do
      expect(second_tdc.reload.condition).to eq(ds_eq(champ_value(1), constant('2')))
      expect(assigns(:coordinate)).to eq(procedure.draft_revision.coordinate_for(second_tdc))
      expect(assigns(:upper_tdcs)).to eq([first_coordinate.type_de_champ])
    end
  end

  describe '#add_row' do
    before { post :add_row, params: default_params, format: :turbo_stream }

    it do
      expect(second_tdc.reload.condition).to eq(empty_operator(empty, empty))
      expect(assigns(:coordinate)).to eq(procedure.draft_revision.coordinate_for(second_tdc))
      expect(assigns(:upper_tdcs)).to eq([first_coordinate.type_de_champ])
    end
  end

  describe '#delete_row' do
    before { delete :delete_row, params: params.merge(row_index: 0), format: :turbo_stream }

    let(:params) { default_params.merge(type_de_champ: { condition_form: condition_form }) }

    let(:condition_form) do
      {
        rows: [
          {
            targeted_champ: champ_value(1).to_json,
            operator_name: Logic::Eq.name,
            value: '2'
          }
        ]
      }
    end

    it do
      expect(second_tdc.reload.condition).to eq(nil)
      expect(assigns(:coordinate)).to eq(procedure.draft_revision.coordinate_for(second_tdc))
      expect(assigns(:upper_tdcs)).to eq([first_coordinate.type_de_champ])
    end
  end

  describe '#destroy' do
    before do
      second_tdc.update(condition: empty_operator(empty, empty))
      delete :destroy, params: default_params, format: :turbo_stream
    end

    it do
      expect(second_tdc.reload.condition).to eq(nil)
      expect(assigns(:coordinate)).to eq(procedure.draft_revision.coordinate_for(second_tdc))
      expect(assigns(:upper_tdcs)).to eq([first_coordinate.type_de_champ])
    end
  end

  describe '#change_targeted_champ' do
    let!(:number_tdc) { create(:type_de_champ_integer_number) }

    before do
      second_tdc.update(condition: empty_operator(empty, empty))
      patch :change_targeted_champ, params: params, format: :turbo_stream
    end

    let(:params) { default_params.merge(type_de_champ: { condition_form: condition_form }) }

    let(:condition_form) do
      {
        rows: [
          {
            targeted_champ: champ_value(number_tdc.stable_id).to_json,
            operator_name: Logic::EmptyOperator.name,
            value: empty.to_json
          }
        ]
      }
    end

    it do
      expect(second_tdc.reload.condition).to eq(ds_eq(champ_value(number_tdc.stable_id), constant(0)))
      expect(assigns(:coordinate)).to eq(procedure.draft_revision.coordinate_for(second_tdc))
      expect(assigns(:upper_tdcs)).to eq([first_coordinate.type_de_champ])
    end
  end
end
