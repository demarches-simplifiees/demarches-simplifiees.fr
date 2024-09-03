# frozen_string_literal: true

class Procedure::OneGroupeManagementComponent < ApplicationComponent
  include Logic

  def initialize(revision:, groupe_instructeur:)
    @revision = revision
    @groupe_instructeur = groupe_instructeur
    @procedure = revision.procedure
  end
end
