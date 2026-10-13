# frozen_string_literal: true

class Columns::DemandeurSiretColumn < Columns::DossierColumn
  SIRET_SQL = 'COALESCE(etablissements.siret, demandeur_sirets.siret)'

  def value(dossier) = dossier.siret

  def sorted_ids(dossiers, order, **)
    direction = order == 'desc' ? 'DESC' : 'ASC'

    dossiers
      .left_joins(:etablissement, :demandeur_siret)
      .order(Arel.sql("#{SIRET_SQL} #{direction}"))
      .pluck(:id)
  end

  def filtered_ids_for_values(dossiers, values)
    return dossiers.ids unless values.any?(&:present?)

    terms = values.compact_blank.map { "%#{ActiveRecord::Base.sanitize_sql_like(it.strip)}%" }

    dossiers
      .left_joins(:etablissement, :demandeur_siret)
      .where("unaccent(#{SIRET_SQL}) ILIKE ANY (ARRAY((SELECT unaccent(unnest(ARRAY[?])))))", terms)
      .ids
  end
end
