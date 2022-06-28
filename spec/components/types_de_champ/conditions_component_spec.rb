describe TypesDeChamp::ConditionsComponent, type: :component do
  include Logic

  describe 'render' do
    let(:tdc) { create(:type_de_champ, condition: condition) }
    let(:condition) { nil }
    let(:upper_tdcs) { [] }

    before { render_inline(described_class.new(tdc: tdc, upper_tdcs: upper_tdcs, procedure_id: 123)) }

    context 'when there are no upper tdc' do
      it { expect(page).not_to have_text('Logique conditionnelle') }
    end

    context 'when there are upper tdcs but not managed' do
      let(:upper_tdcs) { [build(:type_de_champ_address)] }

      it { expect(page).not_to have_text('Logique conditionnelle') }
    end

    context 'when there are upper tdc but no condition to display' do
      let(:upper_tdcs) { [build(:type_de_champ)] }

      it do
        expect(page).to have_text('Logique conditionnelle')
        expect(page).to have_button('cliquer pour activer')
        expect(page).not_to have_selector('table')
      end
    end

    context 'when there are upper tdc and a condition' do
      let(:upper_tdc) { create(:type_de_champ_number) }
      let(:upper_tdcs) { [upper_tdc] }

      context 'and one condition' do
        let(:condition) { ds_eq(champ_value(upper_tdc.stable_id), constant(1)) }

        it do
          expect(page).to have_button('cliquer pour desactiver')
          expect(page).to have_selector('table')
          expect(page).to have_selector('tbody > tr', count: 1)
        end
      end

      context 'focus one row' do
        context 'empty' do
          let(:condition) { empty_operator(empty, empty) }

          it do
            expect(page).to have_select('type_de_champ[condition_form][rows][][operator_name]', options: ['Est'])
            expect(page).to have_select('type_de_champ[condition_form][rows][][value]', options: ['Sélectionner'])
          end
        end

        context 'number' do
          let(:condition) { empty_operator(constant(1), constant(0)) }

          it do
            expect(page).to have_select('type_de_champ[condition_form][rows][][operator_name]', with_options: ['Équal à'])
            expect(page).to have_selector('input[name="type_de_champ[condition_form][rows][][value]"][value=0]')
          end
        end

        context 'boolean' do
          let(:condition) { empty_operator(constant(true), constant(true)) }

          it do
            expect(page).to have_select('type_de_champ[condition_form][rows][][operator_name]', with_options: ['Est'])
            expect(page).to have_select('type_de_champ[condition_form][rows][][value]', options: ['Oui', 'Non'])
          end
        end

        context 'enum' do
          let(:drop_down) { create(:type_de_champ_drop_down_list) }
          let(:upper_tdcs) { [drop_down] }
          let(:condition) { empty_operator(champ_value(drop_down.stable_id), constant(true)) }

          it do
            expect(page).to have_select('type_de_champ[condition_form][rows][][operator_name]', with_options: ['Est'])
            expect(page).to have_select('type_de_champ[condition_form][rows][][value]', options: ['val1', 'val2', 'val3'])
          end
        end

        context 'text' do
          let(:condition) { empty_operator(constant('a'), constant('a')) }

          it do
            expect(page).to have_select('type_de_champ[condition_form][rows][][operator_name]', with_options: ['Est'])
            expect(page).to have_selector('input[name="type_de_champ[condition_form][rows][][value]"][value=""]')
          end
        end
      end

      context 'and 2 conditions' do
        let(:condition) { ds_and([empty_operator(empty, empty), empty_operator(empty, empty)]) }

        it do
          expect(page).to have_selector('tbody > tr', count: 2)
          expect(page).to have_select("type_de_champ_condition_form_top_operator_name", selected: "Et", options: ['Et', 'Ou'])
        end
      end

      context 'when there are 3 conditions' do
        let(:upper_tdc) { create(:type_de_champ_number) }
        let(:upper_tdcs) { [upper_tdc] }

        let(:condition) do
          ds_or([
            ds_eq(champ_value(upper_tdc.stable_id), constant(1)),
            ds_eq(champ_value(upper_tdc.stable_id), empty),
            greater_than(champ_value(upper_tdc.stable_id), constant(3))
          ])
        end

        it do
          expect(page).to have_selector('tbody > tr', count: 3)
          expect(page).to have_select("type_de_champ_condition_form_top_operator_name", selected: "Ou", options: ['Et', 'Ou'])
        end
      end
    end
  end

  describe '.rows' do
    let(:tdc) { build(:type_de_champ, condition: condition) }
    let(:condition) { nil }

    subject { described_class.new(tdc: tdc, upper_tdcs: [], procedure_id: 123).send(:rows) }

    context 'when there is one condition' do
      let(:condition) { ds_eq(empty, constant(1)) }

      it { is_expected.to eq([[empty, Logic::Eq.name, constant(1)]]) }
    end

    context 'when there are 2 conditions' do
      let(:condition) { ds_and([ds_eq(empty, constant(1)), ds_eq(empty, empty)]) }

      let(:expected) do
        [
          [empty, Logic::Eq.name, constant(1)],
          [empty, Logic::Eq.name, empty]
        ]
      end

      it { is_expected.to eq(expected) }
    end

    context 'when there are 3 conditions' do
      let(:upper_tdc) { create(:type_de_champ_number) }
      let(:upper_tdcs) { [upper_tdc] }

      let(:condition) do
        ds_or([
          ds_eq(champ_value(upper_tdc.stable_id), constant(1)),
          ds_eq(champ_value(upper_tdc.stable_id), empty),
          greater_than(champ_value(upper_tdc.stable_id), constant(3))
        ])
      end

      let(:expected) do
        [
          [champ_value(upper_tdc.stable_id), Logic::Eq.name, constant(1)],
          [champ_value(upper_tdc.stable_id), Logic::Eq.name, empty],
          [champ_value(upper_tdc.stable_id), Logic::GreaterThan.name, constant(3)]
        ]
      end

      it { is_expected.to eq(expected) }
    end
  end
end
