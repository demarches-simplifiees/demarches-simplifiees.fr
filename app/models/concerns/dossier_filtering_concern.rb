# frozen_string_literal: true

module DossierFilteringConcern
  extend ActiveSupport::Concern

  included do
    DATE_SINCE_MAPPING = {
      'updated_since' => 'updated_at',
      'depose_since' => 'depose_at',
      'en_construction_since' => 'en_construction_at',
      'en_instruction_since' => 'en_instruction_at',
      'processed_since' => 'processed_at'
    }
    scope :filter_by_datetimes, lambda { |column, dates|
      if dates.present?
        case column
        when 'sva_svr_decision_before'
          state_not_termine.where("dossiers.sva_svr_decision_on": ..dates.sort.first)
        when *DATE_SINCE_MAPPING.keys
          where("dossiers.#{DATE_SINCE_MAPPING.fetch(column)}": dates.sort.first..)
        else
          dates
            .map { |date| self.where(column => date..(date + 1.day)) }
            .reduce(:or)
        end
      else
        none
      end
    }

    scope :filter_by_datetimes_range, lambda { |column, date_range|
      case column
      when 'sva_svr_decision_before'
        state_not_termine.where("dossiers.sva_svr_decision_on": date_range)
      when *DATE_SINCE_MAPPING.keys
        where("dossiers.#{DATE_SINCE_MAPPING.fetch(column)}": date_range)
      else
        where(column => date_range)
      end
    }

    scope :filter_ilike, lambda { |table, column, search_terms|
      safe_quoted_terms = search_terms.map(&:strip).map { "%#{sanitize_sql_like(_1)}%" }
      table_column = DossierFilterService.sanitized_column(table, column)

      where("unaccent(#{table_column}) ILIKE ANY (ARRAY((SELECT unaccent(unnest(ARRAY[?])))))", safe_quoted_terms)
    }

    def sanitize_sql_like(q) = ActiveRecord::Base.sanitize_sql_like(q)
  end
end
