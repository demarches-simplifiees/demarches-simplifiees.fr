# frozen_string_literal: true

module Maintenance
  class T20251003normalizeProcedurePresentationFiltersTask < MaintenanceTasks::Task
    # Documentation: normalise les valeurs des filtres ProcedurePresentation
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    FILTER_ATTRIBUTES = [
      :a_suivre_filters,
      :suivis_filters,
      :traites_filters,
      :tous_filters,
      :supprimes_filters,
      :supprimes_recemment_filters,
      :expirant_filters,
      :archives_filters
    ].freeze

    def collection
      ProcedurePresentation.includes(assign_to: :procedure)
    end

    def process(pp)
      FILTER_ATTRIBUTES.each do |attribute|
        begin
          current_filters = pp.public_send(attribute)
        rescue ActiveRecord::RecordNotFound
          next
        end

        next if current_filters.blank?

        normalized_filters = current_filters.map do |filter|
          normalized_filter = ValueNormalizer.normalize(filter.filter)

          normalized_filter == filter.filter ? filter : FilteredColumn.new(column: filter.column, filter: normalized_filter)
        end

        pp.public_send("#{attribute}=", normalized_filters)
      end

      pp.save!
    end
  end
end
