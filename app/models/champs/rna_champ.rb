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
#  dossier_id                     :integer          not null
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer          not null
#  row_id                         :string
#
class Champs::RNAChamp < Champ
  validates :value, allow_blank: true, format: {
    with: /\AW[0-9]{9}\z/, message: I18n.t(:not_a_rna, scope: 'activerecord.errors.messages')
  }, if: -> { validation_context != :brouillon }

  delegate :id, to: :procedure, prefix: true

  def title
    data&.dig("association_titre")
  end

  def identifier
    title.present? ? "#{value} (#{title})" : value
  end

  def for_export
    identifier
  end

  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end
end
