# frozen_string_literal: true

class Dossiers::DeletedDossiersComponent < ApplicationComponent
  include DossierHelper

  def initialize(deleted_dossiers:)
    @deleted_dossiers = deleted_dossiers
  end

  def role
    controller.try(:nav_bar_profile)
  end
end
