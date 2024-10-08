# frozen_string_literal: true

class Procedure::Card::ChampsComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
    @count = @procedure.draft_revision.types_de_champ.public_only.size
  end

  private

  def error_messages
    @procedure.errors.messages_for(:draft_types_de_champ_public).to_sentence
  end
end
