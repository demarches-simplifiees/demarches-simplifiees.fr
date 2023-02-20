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
        when *DATE_SINCE_MAPPING.keys
          where("dossiers.#{DATE_SINCE_MAPPING.fetch(column)} >= ?", dates.sort.first)
        else
          dates
            .map { |date| self.where(column => date..(date + 1.day)) }
            .reduce(:or)
        end
      else
        none
      end
    }

    scope :filter_ilike, lambda { |table, column, values|
      table_column = ProcedurePresentation.sanitized_column(table, column)
      q = Array.new(values.count, "(#{table_column} ILIKE ?)").join(' OR ')
      where(q, *(values.map { |value| "%#{value}%" }))
    }
  end
end
