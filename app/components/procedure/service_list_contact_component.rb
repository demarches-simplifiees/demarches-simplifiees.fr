# frozen_string_literal: true

class Procedure::ServiceListContactComponent < ApplicationComponent
  attr_reader :procedure, :service, :dossier

  def initialize(service:, dossier:)
    @service = service
    @dossier = dossier
  end
end
