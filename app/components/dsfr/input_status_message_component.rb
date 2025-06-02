# frozen_string_literal: true

module Dsfr
  class InputStatusMessageComponent < ApplicationComponent
    def initialize(errors_on_attribute:, error_full_messages:, describedby_id:, champ:)
      @errors_on_attribute = errors_on_attribute
      @error_full_messages = error_full_messages
      @describedby_id = describedby_id
      @champ = champ
    end
  end
end
