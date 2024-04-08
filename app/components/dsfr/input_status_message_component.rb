module Dsfr
  class InputStatusMessageComponent < ApplicationComponent
    def initialize(errors_on_attribute:, error_full_messages:, described_by:, champ:)
      @errors_on_attribute = errors_on_attribute
      @error_full_messages = error_full_messages
      @described_by = described_by
      @champ = champ
    end

    def render?
      @errors_on_attribute
    end
  end
end
