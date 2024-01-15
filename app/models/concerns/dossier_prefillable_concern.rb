# frozen_string_literal: true

module DossierPrefillableConcern
  extend ActiveSupport::Concern

  def prefill!(champs_attributes, identity_attributes)
    return if champs_attributes.empty? && identity_attributes.empty?

    attributes = { prefilled: true }
    attributes[:champs_attributes] = champs_attributes.map { |h| h.merge(prefilled: true) }
    attributes[:individual_attributes] = identity_attributes if identity_attributes.present?

    assign_attributes(attributes)
    save(validate: false)
  end

  def find_champs_by_stable_ids(stable_ids)
    champs.joins(:type_de_champ).where(types_de_champ: { stable_id: stable_ids.compact.uniq })
  end
end
