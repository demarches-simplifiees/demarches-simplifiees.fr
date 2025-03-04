# frozen_string_literal: true

class Instructeurs::RdvCardComponent < ApplicationComponent
  attr_reader :rdv, :with_dossier_infos

  def initialize(rdv:, with_dossier_infos: false)
    @rdv = rdv
    @with_dossier_infos = with_dossier_infos
  end

  def dossier
    @rdv.dossier
  end
end
