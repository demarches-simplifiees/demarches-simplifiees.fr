# frozen_string_literal: true

class TypesDeChampEditor::HeaderSectionComponent < ApplicationComponent
  MAX_LEVEL = 3

  def initialize(form:, tdc:, upper_tdcs:)
    @form = form
    @tdc = tdc
    @upper_tdcs = upper_tdcs
  end

  def header_section_options_for_select
    closest_level = @tdc.previous_section_level(@upper_tdcs)
    next_level = [closest_level + 1, MAX_LEVEL].min

    available_levels = (1..next_level).map(&method(:option_for_level))
    disabled_levels = errors? ? (next_level + 1..MAX_LEVEL).map(&method(:option_for_level)) : []
    options_for_select(
      available_levels + disabled_levels,
      disabled: disabled_levels.map(&:second),
      selected: @tdc.header_section_level_value
    )
  end

  def errors
    @tdc.check_coherent_header_level(@upper_tdcs)
  end

  private

  def option_for_level(level)
    [translate(".select_option", level: level), level]
  end

  def errors?
    errors.present?
  end

  def to_html_list(messages)
    messages
      .map { |message| tag.li(message) }
      .then { |lis| tag.ul(lis.reduce(&:+)) }
  end
end
