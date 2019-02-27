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
  end
end
