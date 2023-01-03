# frozen_string_literal: true

module DossierPrefillableConcern
  extend ActiveSupport::Concern

  def prefill!(champs_public_attributes)
    attr = { prefilled: true }
    attr[:champs_public_attributes] = champs_public_attributes.map { |h| h.merge(prefilled: true) } if champs_public_attributes.any?

    assign_attributes(attr)
    save(validate: false)
  end
end
