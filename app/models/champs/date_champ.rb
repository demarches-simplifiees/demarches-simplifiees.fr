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
class Champs::DateChamp < Champ
  before_validation :format_before_save
  validate :iso_8601

  def search_terms
    # Text search is pretty useless for dates so we’re not including these champs
  end

  def to_s
    value.present? ? I18n.l(Time.zone.parse(value), format: '%d %B %Y') : ""
  end

  def for_tag
    value.present? ? I18n.l(Time.zone.parse(value), format: '%d %B %Y') : ""
  end

  private

  def format_before_save
    self.value = nil if !valid_iso8601?(value)
  end

  def iso_8601
    return if valid_iso8601?(value)
    # i18n-tasks-use t('errors.messages.not_a_datetime')
    errors.add :date, errors.generate_message(:value, :not_a_date)
  end

  def valid_iso8601?(value)
    Date.iso8601(value)
    true
  rescue ArgumentError, Date::Error # rubocop:disable Lint/ShadowedException
    false
  end
end
