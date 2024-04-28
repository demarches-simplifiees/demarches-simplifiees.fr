# frozen_string_literal: true

class Procedure::SearchComponent < ApplicationComponent
  def initialize(grouped_procedures:)
    @grouped_procedures = grouped_procedures
  end
end
