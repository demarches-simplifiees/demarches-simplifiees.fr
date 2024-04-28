# frozen_string_literal: true

class APIEntreprise::EffectifsJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    etablissement = Etablissement.find(etablissement_id)
    etablissement_params = APIEntreprise::EffectifsAdapter.new(etablissement.siret, procedure_id, *get_current_valid_month_for_effectif).to_params
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
