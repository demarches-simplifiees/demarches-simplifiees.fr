class Procedure::GroupesSearchComponent < ApplicationComponent
  def initialize(procedure:, query:, to_configure_count:)
    @procedure, @query, @to_configure_count = procedure, query, to_configure_count
  end
end
