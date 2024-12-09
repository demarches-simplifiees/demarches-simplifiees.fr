# frozen_string_literal: true

module ChampValidateConcern
  extend ActiveSupport::Concern

  included do
    protected

    # Champs public/private must be validated depending on the context
    def valid_champ_value?
      valid?(public? ? :champs_public_value : :champs_private_value)
    end

    private

    def validate_champ_value?
      case validation_context
      when :champs_public_value
        public? && can_validate? && visible?
      when :champs_private_value
        private? && can_validate? && visible?
      when :prefill
        can_validate? && visible?
      else
        # FIXME: this is a temporary fix to avoid breaking specs
        if is_a?(Champs::PieceJustificativeChamp) || is_a?(Champs::TitreIdentiteChamp)
          validation_context != :create && can_validate?
        else
          false
        end
      end
    end

    def can_validate?
      in_dossier_revision? && is_same_type_as_revision? && !row? && !in_discarded_row?
    end
  end
end
