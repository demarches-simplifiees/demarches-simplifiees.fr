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
end
