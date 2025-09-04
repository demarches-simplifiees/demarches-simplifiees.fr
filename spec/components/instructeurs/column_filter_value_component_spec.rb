# frozen_string_literal: true

describe Instructeurs::ColumnFilterValueComponent, type: :component do
  before do
    component = nil

    ActionView::Base.empty.form_with(url: "/") do |form|
      component = described_class.new(column:, form:)
    end

    render_inline(component)
  end

  describe 'the select case' do
    let!(:column) do
      column = double("Column", type: :enum, tdc_type: "drop_down_list", options_for_select:, mandatory: true)
      allow(column).to receive(:is_a?).with(Columns::ChampColumn).and_return(true)
      column
    end
    let(:options_for_select) { ['option1', 'option2'] }

    let(:react_component) { page.find('react-component') }
    let(:react_props_items) { JSON.parse(react_component['props']) }

    it {
      expect(react_props_items["items"]).to eq([
        "option1", "option2"
      ])
    }
  end

  describe 'the input case' do
    let(:column) { double("Column", type: :datetime, mandatory: true) }

    it { expect(page).to have_selector('input[name="filter[filter][value][]"][type="date"]', count: 1) }
  end

  describe 'the column empty case' do
    let(:column) { nil }

    it { expect(page).to have_selector('input[disabled]', count: 1) }
  end

  describe 'the yes no case' do
    let(:column) { double("Column", type: :boolean, tdc_type: "yes_no", options_for_select: Champs::YesNoChamp.options, mandatory:) }

    context 'when the column is mandatory' do
      let(:mandatory) { true }
      it { expect(page).to have_selector('input[name="filter[filter][value][]"][type="radio"]', count: 2) }
      it { expect(page).to have_selector('label[for="filter[filter][value][]_true"]', text: 'oui') }
      it { expect(page).to have_selector('label[for="filter[filter][value][]_false"]', text: 'non') }
    end

    context 'when the column is not mandatory' do
      let(:mandatory) { false }

      it { expect(page).to have_selector('input[name="filter[filter][value][]"][type="radio"]', count: 3) }
      it { expect(page).to have_selector('label[for="filter[filter][value][]_true"]', text: 'oui') }
      it { expect(page).to have_selector('label[for="filter[filter][value][]_false"]', text: 'non') }

      it { expect(page).to have_selector('label[for="filter[filter][value][]_nil"]', text: 'Non renseigné') }
    end
  end

  describe 'the checkbox case' do
    let(:column) { double("Column", type: :boolean, tdc_type: "checkbox", options_for_select: Champs::CheckboxChamp.options, mandatory:) }

    context 'when the column is mandatory' do
      let(:mandatory) { true }

      it { expect(page).to have_selector('input[name="filter[filter][value][]"][type="radio"]', count: 2) }
      it { expect(page).to have_selector('label[for="filter[filter][value][]_true"]', text: 'coché') }
      it { expect(page).to have_selector('label[for="filter[filter][value][]_false"]', text: 'non coché') }

      # it { expect(page).to have_selector('input[name="filter[filter][value][]"][type="checkbox"]') }
    end

    context 'when the column is not mandatory' do
      let(:mandatory) { false }

      it { expect(page).to have_selector('input[name="filter[filter][value][]"][type="radio"]', count: 2) }
      it { expect(page).to have_selector('label[for="filter[filter][value][]_true"]', text: 'coché') }
      it { expect(page).to have_selector('label[for="filter[filter][value][]_false"]', text: 'non coché') }
    end
  end
end
