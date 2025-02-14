# frozen_string_literal: true

module Dsfr
  class InputStatusMessageComponent < ApplicationComponent
    def initialize(errors_on_attribute:, error_full_messages:, champ:)
      @errors_on_attribute = errors_on_attribute
      @error_full_messages = error_full_messages
      @error_id = champ.error_id
      @champ = champ
    end

    def statutable?
      supports_statut? && @champ.value.present?
    end

    def supports_statut?
      @champ.type_de_champ.type_champ.in?([
        TypeDeChamp.type_champs[:rna]
      ])
    end

    def statut_message
      case @champ.type_de_champ.type_champ
      when TypeDeChamp.type_champs[:rna]
        t(".rna.data_fetched", title: @champ.title, address: @champ.full_address)
      end
    end
  end
end
