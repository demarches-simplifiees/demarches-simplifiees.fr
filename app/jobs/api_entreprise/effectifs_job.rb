class ApiEntreprise::EffectifsJob < ApiEntreprise::Job
  def perform(etablissement_id, procedure_id)
    etablissement = Etablissement.find(etablissement_id)
    # effectifs endpoint currently only works when asking for february 2020 month
    etablissement_params = ApiEntreprise::EffectifsAdapter.new(etablissement.siret, procedure_id, "2020", "02").to_params
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
