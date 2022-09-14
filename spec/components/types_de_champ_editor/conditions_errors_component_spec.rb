describe TypesDeChampEditor::ConditionsErrorsComponent, type: :component do
  include Logic

  describe 'render' do
    let(:conditions) { [] }
    let(:upper_tdcs) { [] }

    before { render_inline(described_class.new(conditions: conditions, upper_tdcs: upper_tdcs)) }

    context 'when there are no condition' do
      it { expect(page).to have_no_css('.condition-error') }
    end

    context 'when the targeted_champ is not available' do
      let(:tdc) { create(:type_de_champ_integer_number) }
      let(:conditions) { [ds_eq(champ_value(tdc.stable_id), constant(1))] }

      it do
        expect(page).to have_css('.condition-error')
        expect(page).to have_content("Un champ cible n'est plus disponible")
      end
    end

    context 'when the targeted_champ is unmanaged' do
      let(:tdc) { create(:type_de_champ_address) }
      let(:upper_tdcs) { [tdc] }
      let(:conditions) { [ds_eq(champ_value(tdc.stable_id), constant(1))] }

      it do
        expect(page).to have_css('.condition-error')
        expect(page).to have_content("Le champ « #{tdc.libelle} » est de type « adresse » et ne peut pas être utilisé comme champ cible.")
      end
    end

    context 'when the types mismatch' do
      let(:tdc) { create(:type_de_champ_integer_number) }
      let(:upper_tdcs) { [tdc] }
      let(:conditions) { [ds_eq(champ_value(tdc.stable_id), constant('a'))] }

      it { expect(page).to have_content("Le champ « #{tdc.libelle} » est de type « nombre entier ». Il ne peut pas être égal à a.") }
    end

    context 'when a number operator is applied on not a number' do
      let(:tdc) { create(:type_de_champ_multiple_drop_down_list) }
      let(:upper_tdcs) { [tdc] }
      let(:conditions) { [greater_than(champ_value(tdc.stable_id), constant('a text'))] }

      it { expect(page).to have_content("« Supérieur à » ne s'applique qu'à des nombres.") }
    end

    context 'when the include operator is applied on a list' do
      let(:tdc) { create(:type_de_champ_integer_number) }
      let(:upper_tdcs) { [tdc] }
      let(:conditions) { [ds_include(champ_value(tdc.stable_id), constant('a text'))] }

      it { expect(page).to have_content("Lʼopérateur « inclus » ne s'applique qu'au choix simple ou multiple.") }
    end

    context 'when a choice is not in a drop_down' do
      let(:tdc) { create(:type_de_champ_drop_down_list) }
      let(:upper_tdcs) { [tdc] }
      let(:conditions) { [ds_eq(champ_value(tdc.stable_id), constant('another choice'))] }

      it { expect(page).to have_content("« another choice » ne fait pas partie de « #{tdc.libelle} ».") }
    end

    context 'when a choice is not in a multiple_drop_down' do
      let(:tdc) { create(:type_de_champ_multiple_drop_down_list) }
      let(:upper_tdcs) { [tdc] }
      let(:conditions) { [ds_include(champ_value(tdc.stable_id), constant('another choice'))] }

      it { expect(page).to have_content("« another choice » ne fait pas partie de « #{tdc.libelle} ».") }
    end
  end
end
