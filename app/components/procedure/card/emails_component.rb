# frozen_string_literal: true

class Procedure::Card::EmailsComponent < ApplicationComponent
  CUSTOMIZABLE_COUNT = 6

  def initialize(procedure:)
    @procedure = procedure
  end

  def customized_progress
    "#{customized_count} / #{CUSTOMIZABLE_COUNT}"
  end

  def fully_customized?
    customized_count == CUSTOMIZABLE_COUNT
  end

  private

  def error_messages
    [
      @procedure.errors.messages_for(:initiated_mail),
      @procedure.errors.messages_for(:received_mail),
      @procedure.errors.messages_for(:closed_mail),
      @procedure.errors.messages_for(:refused_mail),
      @procedure.errors.messages_for(:without_continuation_mail),
    ].flatten.to_sentence
  end

  def customized_count
    [
      @procedure.initiated_mail,
      @procedure.received_mail,
      @procedure.closed_mail,
      @procedure.refused_mail,
      @procedure.without_continuation_mail,
      @procedure.re_instructed_mail,
    ].map { |mail| mail&.updated_at }.compact.size
  end
end
