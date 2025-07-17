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
      prefilled? ||
      pjs_statut?
    end

    def rna_support_statut?
      type_de_champ.rna? && @champ.value.present?
    end

    def referentiel_support_statut?
      type_de_champ.referentiel? && (
        @champ.waiting_for_external_data? ||
        @champ.external_error_present? ||
        @champ.value.present?
      )
    end

    def pjs_statut?
      @champ.RIB? && @champ.piece_justificative_file.blobs.any?
    end

    def statut_message
      return { state: :info, text: t('.prefilled') } if prefilled?
      case @champ.type_de_champ.type_champ
      when TypeDeChamp.type_champs[:rna]
        { state: :info, text: t(".rna.data_fetched", title: @champ.title, address: @champ.full_address) }
      when TypeDeChamp.type_champs[:referentiel]
        if @champ.waiting_for_external_data?
          { state: :info, text: t(".referentiel.fetching") }
        elsif @champ.external_error_present?
          { state: :info, text: t(".referentiel.error", value: @champ.external_id) }
        elsif @champ.value.present?
          { state: :valid, text: t(".referentiel.success", value: @champ.value) }
        end
      when TypeDeChamp.type_champs[:piece_justificative]
        value_json = @champ.value_json
        iban = value_json&.dig('rib', 'iban')
        bank_name = value_json&.dig('rib', 'bank_name')

        if @champ.waiting_for_external_data?
          { state: :info, text: t('.pj.info') }
        elsif @champ.external_error_present?
          { state: :warning, text: t('.pj.error') }
        elsif iban.nil?
          { state: :warning, text: t('.pj.warning') }
        else
          text = bank_name.present? ? t('.pj.valid_with_bank', iban:, bank_name:) : t('.pj.valid', iban:)
          { state: :valid, text: }
        end

      end
    end
  end
end
