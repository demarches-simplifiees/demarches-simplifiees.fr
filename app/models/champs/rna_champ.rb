# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
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
#
class Champs::RNAChamp < Champ
  validates :value, allow_blank: true, format: {
    with: /\AW[0-9]{9}\z/, message: I18n.t(:not_a_rna, scope: 'activerecord.errors.messages')
  }
  after_validation :update_external_id, if: -> { value_changed? }

  delegate :id, to: :procedure, prefix: true

  def for_export
    data&.dig("association_titre")&.present? ? "#{value} (#{data.dig("association_titre")})" : value
  end

  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end

  def fetch_external_data?
    true
  end

  def fetch_external_data
    APIEntreprise::RNAAdapter.new(external_id, procedure_id).to_params
  end

  def update_external_id
    self.external_id = self.value
  end
end
