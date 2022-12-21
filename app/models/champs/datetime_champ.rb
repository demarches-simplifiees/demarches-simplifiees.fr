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
#  row                            :integer
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champs::DatetimeChamp < Champ
  before_validation :format_before_save
  validate :iso_8601

  def search_terms
    # Text search is pretty useless for datetimes so we’re not including these champs
  end

  def to_s
    value.present? ? I18n.l(Time.zone.parse(value)) : ""
  end

  def for_tag
    value.present? ? I18n.l(Time.zone.parse(value)) : ""
  end

  def html_label?
    false
  end

  private

  def format_before_save
    if (value =~ /=>/).present?
      self.value =
        begin
          hash_date = YAML.safe_load(value.gsub('=>', ': '))
          year, month, day, hour, minute = hash_date.values_at(1, 2, 3, 4, 5)
          DateTime.iso8601(Time.zone.local(year, month, day, hour, minute))
        rescue
          nil
        end
    elsif /^\d{2}\/\d{2}\/\d{4}\s\d{2}:\d{2}$/.match?(value) # old browsers can send with dd/mm/yyyy hh:mm format
      self.value = DateTime.iso8601(Time.zone.strptime(value, "%d/%m/%Y %H:%M"))
    elsif !valid_iso8601?(value) # a datetime not correctly formatted should not be stored
      self.value = nil
    end
  end

  def iso_8601
    return if valid_iso8601?(value)
    # i18n-tasks-use t('errors.messages.not_a_datetime')
    errors.add :datetime, errors.generate_message(:value, :not_a_datetime)
  end

  def valid_iso8601?(value)
    DateTime.iso8601(value)
    true
  rescue ArgumentError, Date::Error # rubocop:disable Lint/ShadowedException
    false
  end
end
