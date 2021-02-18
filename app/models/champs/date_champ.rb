# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  row                            :integer
#  type                           :string
#  value                          :string
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champs::DateChamp < Champ
  before_save :format_before_save

  def search_terms
    # Text search is pretty useless for dates so we’re not including these champs
  end

  def to_s
    value.present? ? I18n.l(Time.zone.parse(value), format: '%d %B %Y') : ""
  end

  def for_tag
    value.present? ? I18n.l(Time.zone.parse(value), format: '%d %B %Y') : ""
  end

  def for_export
    value.present? ? Date.parse(value) : ""
  end

  private

  def format_before_save
    self.value =
      begin
        Time.zone.parse(value).to_date.iso8601
      rescue
        nil
      end
  end
end
