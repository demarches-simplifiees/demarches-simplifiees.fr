# See:
# - https://robots.thoughtbot.com/implementing-multi-table-full-text-search-with-postgres
# - http://calebthompson.io/talks/search.html
class Search < ActiveRecord::Base
  # :nodoc:
  #
  # Englobs a search result (actually a collection of Search objects) so it acts
  # like a collection of regular Dossier objects, which can be decorated,
  # paginated, ...
  class Results
    include Enumerable

    def initialize(results)
      @results = results
    end

    def each
      @results.each do |search|
        yield search.dossier
      end
    end

    def method_missing(name, *args, &block)
      @results.__send__(name, *args, &block)
    end

    def decorate!
      @results.each do |search|
        search.dossier = search.dossier.decorate
      end
    end
  end

  attr_accessor :gestionnaire
  attr_accessor :query
  attr_accessor :page

  belongs_to :dossier

  def results
    unless @query.present?
      return Search.none
    end

    search_term = Search.connection.quote(to_tsquery)

    dossier_ids = @gestionnaire.dossiers
      .select(:id)
      .where(archived: false)
      .where.not(state: "draft")

    q = Search
      .select("DISTINCT(searches.dossier_id)")
      .select("COALESCE(ts_rank(to_tsvector('french', searches.term::text), to_tsquery('french', #{search_term})), 0) AS rank")
      .joins(:dossier)
      .where(dossier_id: dossier_ids)
      .where("to_tsvector('french', searches.term::text) @@ to_tsquery('french', #{search_term})")
      .order("rank DESC")
      .preload(:dossier)

    if @page.present?
      q = q.paginate(page: @page)
    end

    Results.new(q)
  end

  #def self.refresh
  #  # TODO: could be executed concurrently
  #  # See https://github.com/thoughtbot/scenic#what-about-materialized-views
  #  Scenic.database.refresh_materialized_view(table_name, concurrently: false)
  #end

  private

  def to_tsquery
    @query.gsub(/['?\\:&|!]/, "") # drop disallowed characters
      .split(/\s+/)               # split words
      .map { |x| "#{x}:*" }       # enable prefix matching
      .join(" & ")
  end
end
