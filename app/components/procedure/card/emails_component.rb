class Procedure::Card::EmailsComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  private

  def error_messages
    [
      @procedure.errors.messages_for(:initiated_mail),
      @procedure.errors.messages_for(:received_mail),
      @procedure.errors.messages_for(:closed_mail),
      @procedure.errors.messages_for(:refused_mail),
      @procedure.errors.messages_for(:without_continuation_mail)
    ].flatten.to_sentence
  end
end
