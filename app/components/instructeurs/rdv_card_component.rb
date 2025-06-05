# frozen_string_literal: true

class Instructeurs::RdvCardComponent < ApplicationComponent
  attr_reader :rdv, :for_user

  def initialize(rdv:, for_user: false)
    @rdv = rdv
    @for_user = for_user
  end

  def dossier
    @rdv.dossier
  end

  def owner
    if @rdv.instructeur == current_instructeur
      t('.you')
    else
      @rdv.instructeur.email
    end
  end

  def icon_class
    case rdv.location_type
    when "phone"
      "fr-icon-phone-fill"
    when "visio"
      "fr-icon-vidicon-fill"
    when "home"
      "fr-icon-home-4-fill"
    end
  end

  def rdv_url
    if @for_user
      RdvService.rdv_sp_rdv_user_url(@rdv.rdv_external_id)
    else
      RdvService.rdv_sp_rdv_agent_url(@rdv.rdv_external_id)
    end
  end
end
