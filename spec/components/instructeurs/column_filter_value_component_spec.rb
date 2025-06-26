# frozen_string_literal: true

describe Instructeurs::ColumnFilterValueComponent, type: :component do
  let(:component) { described_class.new(column:) }

  before { render_inline(component) }

  describe 'the select case' do
    let(:column) { double("Column", type: :enum, options_for_select:) }
    let(:options_for_select) { ['option1', 'option2'] }

    it { expect(page).to have_select('filters[][filter]', options: options_for_select) }
  end

  describe 'the input case' do
    let(:column) { double("Column", type: :datetime) }

    it { expect(page).to have_selector('input[name="filters[][filter]"][type="date"]') }
  end

  describe 'the column empty case' do
    let(:column) { nil }

    it { expect(page).to have_selector('input[disabled]') }
  end

  describe 'the radio button case' do
    let(:column) { double("Column", tdc_type: "yes_no", options_for_select: Champs::YesNoChamp.options) }

    it { expect(page).to have_selector('input[name="filters[][filter]"][type="radio"]') }
  end
end
