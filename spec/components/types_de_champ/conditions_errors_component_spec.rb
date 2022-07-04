describe TypesDeChamp::ConditionsErrorsComponent, type: :component do
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
        expect(page).to have_content("ne peut pas être utilisé")
      end
    end

    context 'when the types mismatch' do
      let(:tdc) { create(:type_de_champ_integer_number) }
      let(:upper_tdcs) { [tdc] }
      let(:conditions) { [ds_eq(champ_value(tdc.stable_id), constant('a'))] }

      it { expect(page).to have_content("Il ne peut pas être") }
    end
  end
end
