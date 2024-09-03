# frozen_string_literal: true

class Procedure::NoticeComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  private

  def render?
    link? || attachment?
  end

  def link?
    @procedure.lien_notice.present?
  end

  def url
    @procedure.lien_notice
  end

  def attachment?
    @procedure.notice.present?
  end

  def attachment
    @procedure.notice
  end
end
