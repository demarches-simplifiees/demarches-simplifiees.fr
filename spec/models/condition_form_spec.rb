describe ConditionForm, type: :model do
  include Logic

  describe 'to_condition' do
    let(:top_operator_name) { '' }

    subject { ConditionForm.new(rows: rows, top_operator_name: top_operator_name).to_condition }

    context 'when a row is added' do
      let(:rows) { [{ targeted_champ: champ_value(1).to_json, operator_name: Logic::Eq.name, value: '1' }] }
      it { is_expected.to eq(ds_eq(champ_value(1), constant(1))) }
    end

    context 'when two rows are added' do
      let(:top_operator_name) { Logic::And.name }
      let(:rows) do
        [
          { targeted_champ: champ_value(1).to_json, operator_name: Logic::Eq.name, value: '2' },
          { targeted_champ: champ_value(3).to_json, operator_name: Logic::GreaterThan.name, value: '4' }
        ]
      end

      let(:expected) do
        ds_and([
          ds_eq(champ_value(1), constant(2)),
          greater_than(champ_value(3), constant(4))
        ])
      end
      it { is_expected.to eq(expected) }
    end

    context 'when 3 rows are added' do
      let(:top_operator_name) { Logic::Or.name }
      let(:rows) do
        [
          { targeted_champ: champ_value(1).to_json, operator_name: Logic::Eq.name, value: '2' },
          { targeted_champ: champ_value(3).to_json, operator_name: Logic::GreaterThan.name, value: '4' },
          { targeted_champ: champ_value(5).to_json, operator_name: Logic::LessThan.name, value: '6' }
        ]
      end

      let(:expected) do
        ds_or([
          ds_eq(champ_value(1), constant(2)),
          greater_than(champ_value(3), constant(4)),
          less_than(champ_value(5), constant(6))
        ])
      end
      it { is_expected.to eq(expected) }
    end
  end
end
