class APIEntreprise::TvaAdapter < APIEntreprise::Adapter
  private

  def get_resource
    api(@procedure_id).tva(siren)
  end

  def process_params
    result = {}
    if data_source[:data]
      result[:entreprise_numero_tva_intracommunautaire] = data_source[:data][:tva_number]
    end
    result
  end
end
