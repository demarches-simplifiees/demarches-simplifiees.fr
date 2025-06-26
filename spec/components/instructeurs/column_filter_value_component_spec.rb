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
    let(:column) { double("Column", type: :enum, options_for_select:) }
    let(:options_for_select) { ['option1', 'option2'] }

    it { expect(page).to have_select('filters[][filter]', options: ['', 'option1', 'option2']) } # empty option is added by form helper but field is required
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
    let(:column) { double("Column", type: :boolean, options_for_select: Champs::YesNoChamp.options) }

    it { expect(page).to have_selector('input[name="filters[][filter]"][type="radio"]') }
  end
end
