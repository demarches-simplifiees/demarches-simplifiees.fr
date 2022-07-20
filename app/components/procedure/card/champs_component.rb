class Procedure::Card::ChampsComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
    @procedure.validate(:publication)
    @count = @procedure.draft_revision.types_de_champ.public_only.size
  end

  private

  def render?
    !@procedure.locked? || @procedure.feature_enabled?(:procedure_revisions)
  end

  def error_messages
    @procedure.errors.messages_for(:draft_types_de_champ).to_sentence
  end
end
