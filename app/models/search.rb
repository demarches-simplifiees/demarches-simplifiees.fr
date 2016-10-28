# See:
# - https://robots.thoughtbot.com/implementing-multi-table-full-text-search-with-postgres
# - http://calebthompson.io/talks/search.html
class Search < ActiveRecord::Base
  extend Textacular

  attr_accessor :gestionnaire
  attr_accessor :query

  belongs_to :dossier

  def results
    if @query.present?
      self.class
        .select("DISTINCT(searches.dossier_id)")
        .search(@query)
        .joins(:dossier)
        .where(dossier_id: @gestionnaire.dossier_ids)
        .where("dossiers.archived = ? AND dossiers.state != ?", false, "draft")
        .preload(:dossier)
        .map(&:dossier)
    else
      Search.none
    end
  end

  def self.searchable_language
    "french"
  end

  def self.searchable_columns
    %i(term)
  end

  # Refreshes the materialized searches view.
  def self.refresh
    # NOTE: could be executed concurrently
    # See https://github.com/thoughtbot/scenic#what-about-materialized-views
    Scenic.database.refresh_materialized_view(table_name, concurrently: false)
  end
end
