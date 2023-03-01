# frozen_string_literal: true

module DossierPrefillableConcern
  extend ActiveSupport::Concern

  def prefill!(champs_public_attributes)
    return unless champs_public_attributes.any?

    attr = { prefilled: true }
    attr[:champs_public_all_attributes] = champs_public_attributes.map { |h| h.merge(prefilled: true) }

    assign_attributes(attr)
    save(validate: false)
  end
end
