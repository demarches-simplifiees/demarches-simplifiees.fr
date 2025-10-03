# frozen_string_literal: true

module Maintenance
  class T20251003normalizeProcedurePresentationFiltersTask < MaintenanceTasks::Task
    FILTER_ATTRIBUTES = %i[
      a_suivre_filters
      suivis_filters
      traites_filters
      tous_filters
      supprimes_filters
      supprimes_recemment_filters
      expirant_filters
      archives_filters
    ].freeze

    def collection
      ProcedurePresentation.all
    end

    def process(procedure_presentation)
      updates = {}

      FILTER_ATTRIBUTES.each do |attribute|
        raw_filters = Array(procedure_presentation.read_attribute_before_type_cast(attribute))
        next if raw_filters.blank?

        normalized_payloads = raw_filters.map do |payload|
          payload_with_indifferent_access = payload.with_indifferent_access
          normalized_filter = ValueNormalizer.normalize(payload_with_indifferent_access[:filter])

          if normalized_filter == payload_with_indifferent_access[:filter]
            payload
          else
            payload.deep_dup.tap { |copy| copy['filter'] = normalized_filter }
          end
        end

        next if normalized_payloads == raw_filters

        normalized_filters = normalized_payloads.map { FilteredColumnType.new.cast(_1) }
        updates[attribute] = normalized_filters
      end

      procedure_presentation.update!(updates) if updates.present?
    end
  end
end
