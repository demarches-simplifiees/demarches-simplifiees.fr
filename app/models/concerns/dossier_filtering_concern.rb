module DossierFilteringConcern
  extend ActiveSupport::Concern

  included do
    scope :filter_by_datetimes, lambda { |column, dates|
      if dates.present?
        dates
          .map { |date| self.where(column => date..(date + 1.day)) }
          .reduce(:or)
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
