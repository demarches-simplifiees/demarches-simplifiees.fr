# frozen_string_literal: true

module DossierPrefillableConcern
  extend ActiveSupport::Concern

  def prefill!(champs_attributes)
    return if champs_attributes.empty?

    assign_attributes(champs_attributes: champs_attributes.map { |h| h.merge(prefilled: true) })
    save(validate: false)
  end
end
