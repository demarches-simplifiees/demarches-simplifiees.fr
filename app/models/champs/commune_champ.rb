# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  prefilled                      :boolean          default(FALSE)
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  row_id                         :string
#  type_de_champ_id               :integer
#
class Champs::CommuneChamp < Champs::TextChamp
  store_accessor :value_json, :code_departement, :code_postal
  before_validation :on_code_postal_change

  def for_export
    [to_s, code? ? code : '', departement? ? departement_code_and_name : '']
  end

  def departement_name
    APIGeoService.departement_name(code_departement)
  end

  def departement_code_and_name
    "#{code_departement} – #{departement_name}"
  end

  def departement
    { code: code_departement, name: departement_name }
  end

  def departement?
    code_departement.present?
  end

  def code?
    code.present?
  end

  def code_postal?
    code_postal.present?
  end

  def code_postal=(value)
    super(value&.gsub(/[[:space:]]/, ''))
  end

  alias postal_code code_postal

  def name
    if code?
      APIGeoService.commune_name(code_departement, code).presence || safe_to_s
    else
      safe_to_s
    end
  end

  def to_s
    if code?
      name = APIGeoService.commune_name(code_departement, code)
      name.present? ? "#{name} (#{code_postal})" : safe_to_s
    else
      safe_to_s
    end
  end

  def code
    external_id
  end

  def selected
    code
  end

  def communes
    if code_postal?
      APIGeoService.communes_by_postal_code(code_postal)
    else
      []
    end
  end

  def value=(code)
    if code.blank? || !code_postal?
      self.code_departement = nil
      self.external_id = nil
      super(nil)
    else
      commune = communes.find { _1[:code] == code }
      if commune.present?
        self.code_departement = commune[:departement_code]
        self.external_id = commune[:code]
        super(commune[:name])
      else
        self.code_departement = nil
        self.external_id = nil
        super(nil)
      end
    end
  end

  private

  def safe_to_s
    value.present? ? value.to_s : ''
  end

  def on_code_postal_change
    if code_postal_changed?
      if communes.one?
        self.value = communes.first[:code]
      else
        self.value = nil
      end
    end
  end
end
