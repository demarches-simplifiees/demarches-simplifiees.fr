# frozen_string_literal: true

class Procedure::GroupesSearchComponent < ApplicationComponent
  def initialize(procedure:, query:, to_configure_count:, to_configure_filter:)
    @procedure = procedure
    @query = query
    @to_configure_count = to_configure_count
    @to_configure_filter = to_configure_filter
  end

  private

  def show_to_configure?
    @to_configure_count > 0
  end
end
