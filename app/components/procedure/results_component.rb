class Procedure::ResultsComponent < ApplicationComponent
  def initialize(grouped_procedures:)
    @grouped_procedures = grouped_procedures
  end
end
