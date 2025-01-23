class LexpolService
  attr_reader :champ, :dossier, :apilexpol

  def initialize(champ:, dossier:, apilexpol: APILexpol.new)
    @champ     = champ
    @dossier   = dossier
    @apilexpol = apilexpol
  end

  def upsert_dossier
    if champ.value.blank?
      create_dossier
    else
      update_dossier
    end
  end

  def create_dossier
    nor = apilexpol.create_dossier(model_id, build_variables)
    return nil if nor.blank?

    champ.update!(value: nor)

    refresh_lexpol_data!

    nor
  rescue => e
    Rails.logger.error("Erreur Lexpol create_dossier : #{e.message}")
    nil
  end

  def update_dossier
    return nil if champ.value.blank?

    apilexpol.update_dossier(champ.value, build_variables)
    refresh_lexpol_data!
    champ.value
  rescue => e
    Rails.logger.error("Erreur Lexpol update_dossier : #{e.message}")
    nil
  end

  def build_variables
    mapping_raw = champ.type_de_champ.lexpol_mapping || ""

    mapping = mapping_raw
      .split("\n")
      .map { |pair| pair.split('=').map(&:strip) }
      .to_h

    variables = {}

    mapping.each do |source_field, target_field|
      raw_values = LexpolFieldsService.object_field_values(dossier, source_field)
      final_values = raw_values.map { |val| LexpolFieldsService.format_lexpol_value(val) }.compact_blank

      next if final_values.blank?

      variables[target_field] = LexpolFieldsService.render_lexpol_values(final_values)
    end

    variables
  end

  def refresh_lexpol_data!
    return if champ.value.blank?

    status_info  = apilexpol.get_dossier_status(champ.value)
    dossier_info = apilexpol.get_dossier_infos(champ.value)

    champ.lexpol_status      = status_info[:libelle]
    champ.lexpol_dossier_url = dossier_info['lienDossier']
    champ.save!
  end

  def model_id
    champ.type_de_champ.options&.[]('lexpol_modele')
  end
end
