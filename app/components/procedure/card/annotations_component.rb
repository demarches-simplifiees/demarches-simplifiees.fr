class Procedure::Card::AnnotationsComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
    @count = @procedure.draft_revision.types_de_champ.private_only.size
  end

  private

  def error_messages
    @procedure.errors.messages_for(:draft_types_de_champ_private).to_sentence
  end
end
