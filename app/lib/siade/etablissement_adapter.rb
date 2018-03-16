class SIADE::EtablissementAdapter
  def initialize(siret, procedure_id)
    @siret = siret
    @procedure_id = procedure_id
  end

  def data_source
    @data_source ||= JSON.parse(SIADE::API.etablissement(@siret, @procedure_id), symbolize_names: true)
  end

  def success?
    data_source
  rescue
    false
  end

  def to_params
    params = data_source[:etablissement].slice(*attr_to_fetch)
    adresse_line = params[:adresse].slice(*address_lines_to_fetch).values.compact.join("\r\n")
    params.merge!(params[:adresse].slice(*address_attr_to_fetch))
    params[:adresse] = adresse_line
    params
  rescue
    nil
  end

  private

  def attr_to_fetch
    [
      :adresse,
      :siret,
      :siege_social,
      :naf,
      :libelle_naf
    ]
  end

  def address_attr_to_fetch
    [
      :numero_voie,
      :type_voie,
      :nom_voie,
      :complement_adresse,
      :code_postal,
      :localite,
      :code_insee_localite
    ]
  end

  def address_lines_to_fetch
    [:l1, :l2, :l3, :l4, :l5, :l6, :l7]
  end
end
