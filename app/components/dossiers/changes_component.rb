# frozen_string_literal: true

class Dossiers::ChangesComponent < ApplicationComponent
  include Dossiers::ChangedColumnFormatting

  attr_reader :changed_columns

  def initialize(changed_columns:)
    @changed_columns = changed_columns
  end

  def render? = changed_columns.present?
end
