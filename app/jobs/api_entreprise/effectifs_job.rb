class APIEntreprise::EffectifsJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    # may 2020 is at the moment the most actual info for effectifs endpoint
    etablissement_params = APIEntreprise::EffectifsAdapter.new(etablissement.siret, procedure_id, "2020", "05").to_params
    etablissement.update!(etablissement_params)
  end

  private

  def get_current_valid_month_for_effectif
    today = Date.today
    date_update = Date.new(today.year, today.month, 15)

    if today >= date_update
      [today.strftime("%Y"), today.strftime("%m")]
    else
      date = today - 1.month
      [date.strftime("%Y"), date.strftime("%m")]
    end
  end
end
