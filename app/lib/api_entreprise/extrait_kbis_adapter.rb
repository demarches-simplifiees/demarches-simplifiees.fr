class APIEntreprise::ExtraitKbisAdapter < APIEntreprise::Adapter
  private

  def get_resource
    api(@procedure_id).extrait_kbis(siren)
  end

  def process_params
    result = {}
    data = data_source[:data]
    if data
      result[:entreprise_capital_social] = data[:capital][:montant] if data[:capital]
      result[:entreprise_nom_commercial] = data[:nom_commercial]
    end
    result
  end
end
