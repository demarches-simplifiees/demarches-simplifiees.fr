class CarteController < ApplicationController
  def show
    @map_filter = MapFilter.new(params.fetch(:map_filter, {}).permit(:kind, :year))
    @map_filter.validate

    # Reset to default params in case of invalid params injection
    @map_filter.kind = MapFilter.new.kind if @map_filter.errors.key?(:kind)
    @map_filter.year = MapFilter.new.year if @map_filter.errors.key?(:year)
    @map_filter.errors.clear

    @map_filter.stats = stats
  end

  private

  def stats
    departements_sql = "select departement, count(procedures.id) as nb_demarches, sum(procedures.estimated_dossiers_count) as nb_dossiers from services inner join procedures on services.id = procedures.service_id where procedures.hidden_at is null and procedures.aasm_state in ('publiee', 'close', 'depubliee')"
    departements_sql += " and procedures.published_at >= '#{@map_filter.year}-01-01' and procedures.published_at <= '#{@map_filter.year}-12-31'" if @map_filter.year.present?
    departements_sql += " group by services.departement"
    departements = ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql(departements_sql))
    departements.to_a.reduce(Hash.new({ nb_demarches: 0, nb_dossiers: 0 })) do |h, v|
      h.merge(
        v["departement"] => {
          'nb_demarches': v["nb_demarches"].presence || 0,
          'nb_dossiers': v['nb_dossiers'].presence || 0
        }
      )
    end
  end
end
