class SIADE::MandatairesSociauxAdapter
  def initialize(siren)
    @siren = siren
  end

  def data_source
    @data_source ||= JSON.parse(SIADE::API.entreprise(@siren), symbolize_names: true)
  rescue
    @data_source = nil
  end

  def to_params
    params = {}

    data_source[:entreprise][:mandataires_sociaux].each_with_index do |mandataire, i|
      params[i] = {}

      mandataire.each do |k, v|
        params[i][k] = v if attr_to_fetch.include?(k)
      end
    end

    params
  rescue
    nil
  end

  def attr_to_fetch
    [:nom,
     :prenom,
     :fonction,
     :date_naissance,
     :date_naissance_timestamp]
  end
end
