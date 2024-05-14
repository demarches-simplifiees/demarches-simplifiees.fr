# frozen_string_literal: true

class CurrentConfirmation < ActiveSupport::CurrentAttributes
  attribute :procedure_after_confirmation
  attribute :prefill_token
end
