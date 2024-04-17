module ChampsValidateConcern
  extend ActiveSupport::Concern

  included do
    protected

    # Champs public/private must be validated depending on the context
    def valid_champ_value?
      valid?(public? ? :champs_public_value : :champs_private_value)
    end

    private

    def validate_champ_value?
      return false unless visible?

      case validation_context
      when :champs_public_value
        public?
      when :champs_private_value
        private?
      else
        false
      end
    end

    def validate_champ_value_or_prefill?
      validate_champ_value? || validation_context == :prefill
    end
  end
end
