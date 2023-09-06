# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  prefilled                      :boolean
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
class Champs::COJOChamp < Champ
  store_accessor :value_json, :accreditation_number, :accreditation_birthdate
  store_accessor :data, :accreditation_success, :accreditation_first_name, :accreditation_last_name

  after_validation :update_external_id

  def accreditation_birthdate
    Date.parse(super)
  rescue ArgumentError, TypeError
    nil
  end

  def accreditation_success?
    accreditation_success == true
  end

  def accreditation_error?
    accreditation_success == false
  end

  def blank?
    accreditation_success.nil?
  end

  def fetch_external_data?
    true
  end

  def poll_external_data?
    true
  end

  def fetch_external_data
    COJOService.new.(accreditation_number:, accreditation_birthdate:)
  end

  def to_s
    "#{accreditation_number} – #{accreditation_birthdate}"
  end

  def accreditation_number_input_id
    "#{input_id}-accreditation_number"
  end

  def accreditation_birthdate_input_id
    "#{input_id}-accreditation_birthdate"
  end

  def focusable_input_id
    accreditation_number_input_id
  end

  private

  def update_external_id
    if accreditation_number_changed? || accreditation_birthdate_changed?
      if accreditation_number.present? && accreditation_birthdate.present? && /\A\d+\z/.match?(accreditation_number)
        self.external_id = { accreditation_number:, accreditation_birthdate: }.to_json
      else
        self.external_id = nil
      end
    end
  end
end
