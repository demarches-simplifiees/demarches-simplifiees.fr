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
class Champs::EpciChamp < Champs::TextChamp
  store_accessor :value_json, :code_departement
  before_validation :on_departement_change

  validate :code_departement_in_departement_codes, unless: -> { code_departement.nil? }
  validate :external_id_in_departement_epci_codes, unless: -> { code_departement.nil? || external_id.nil? }
  validate :value_in_departement_epci_names, unless: -> { code_departement.nil? || external_id.nil? || value.nil? }

  def for_export
    [value, code, "#{code_departement} – #{departement_name}"]
  end

  def departement_name
    APIGeoService.departement_name(code_departement)
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

  def name
    value
  end

  def code
    external_id
  end

  def selected
    code
  end

  def value=(code)
    if code.blank? || !departement?
      self.external_id = nil
      super(nil)
    else
      self.external_id = code
      super(APIGeoService.epci_name(code_departement, code))
    end
  end

  def code_departement_input_id
    "#{input_id}-code_departement"
  end

  def epci_input_id
    "#{input_id}-epci"
  end

  def focusable_input_id
    code_departement_input_id
  end

  private

  def on_departement_change
    if code_departement_changed?
      self.external_id = nil
      self.value = nil
    end
  end

  def code_departement_in_departement_codes
    return if code_departement.in?(APIGeoService.departements.pluck(:code))

    errors.add(:code_departement, :not_in_departement_codes)
  end

  def external_id_in_departement_epci_codes
    return if external_id.in?(APIGeoService.epcis(code_departement).pluck(:code))

    errors.add(:external_id, :not_in_departement_epci_codes)
  end

  def value_in_departement_epci_names
    return if value.in?(APIGeoService.epcis(code_departement).pluck(:name))

    errors.add(:value, :not_in_departement_epci_names)
  end
end
