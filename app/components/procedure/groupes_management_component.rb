# frozen_string_literal: true

class Procedure::GroupesManagementComponent < ApplicationComponent
  def initialize(procedure:, groupe_instructeurs:, query:, to_configure_filter:)
    @procedure = procedure
    @groupe_instructeurs = groupe_instructeurs
    @query = query
    @total = groupe_instructeurs.total_count
    @to_configure_filter = to_configure_filter
  end

  def table_header
    if @query.present?
      if @groupe_instructeurs.length != @total
        "#{t('.groupe', count: @groupe_instructeurs.length)} sur #{@total} #{t('.found', count: @total)}"
      else
        "#{t('.groupe', count: @groupe_instructeurs.length)} #{t('.found', count: @groupe_instructeurs.length)}"
      end
    else
      if @groupe_instructeurs.length != @total
        "#{t('.groupe', count: @groupe_instructeurs.length)} sur #{@total}"
      else
        t('.groupe', count: @groupe_instructeurs.length)
      end
    end
  end
end
