module DossierFilteringConcern
  extend ActiveSupport::Concern

  included do
    scope :filter_by_datetimes, lambda { |column, dates|
      if dates.present?
        case column
        when 'depose_since'
          where('dossiers.depose_at >= ?', dates.sort.first)
        when 'updated_since'
          where('dossiers.updated_at >= ?', dates.sort.first)
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
