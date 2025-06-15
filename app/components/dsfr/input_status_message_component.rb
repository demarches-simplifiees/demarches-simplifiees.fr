# frozen_string_literal: true

module Dsfr
  class InputStatusMessageComponent < ApplicationComponent
    delegate :type_de_champ, to: :@champ
    delegate :prefilled?, to: :@champ
    def initialize(errors_on_attribute:, error_full_messages:, champ:)
      @errors_on_attribute = errors_on_attribute
      @error_full_messages = error_full_messages
      @error_id = champ.error_id
      @champ = champ
    end

    def statutable?
      rna_support_statut? ||
      referentiel_support_statut? ||
      prefilled?
    end

    def rna_support_statut?
      type_de_champ.rna? && @champ.value.present?
    end

    def referentiel_support_statut?
      type_de_champ.referentiel? && (
        @champ.fetch_external_data_pending? ||
        @champ.fetch_external_data_error? ||
        @champ.value.present?
      )
    end

    def statut_message
      return t('.prefilled') if prefilled?
      case @champ.type_de_champ.type_champ
      when TypeDeChamp.type_champs[:rna]
        t(".rna.data_fetched", title: @champ.title, address: @champ.full_address)
      when TypeDeChamp.type_champs[:referentiel]
        if @champ.fetch_external_data_pending?
          t(".referentiel.fetching")
        elsif @champ.fetch_external_data_error?
          t(".referentiel.error", value: @champ.external_id)
        elsif @champ.value.present?
          t(".referentiel.success", value: @champ.value)
        end
      end
    end
  end
end
