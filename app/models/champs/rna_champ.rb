class Champs::RNAChamp < Champ
  include RNAChampAssociationFetchableConcern

  validates :value, allow_blank: true, format: {
    with: /\AW[0-9]{9}\z/, message: I18n.t(:not_a_rna, scope: 'activerecord.errors.messages')
  }, if: :validate_champ_value?

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
