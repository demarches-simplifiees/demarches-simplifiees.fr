# frozen_string_literal: true

class Instructeurs::RdvCardComponent < ApplicationComponent
  attr_reader :rdv

  def initialize(rdv:)
    @rdv = rdv
  end

  def dossier
    @rdv.dossier
  end

  def rdv_url
    @rdv["url_for_agents"]
  end

  def starts_at
    DateTime.parse(@rdv["starts_at"])
  end

  def location_type
    @rdv["motif"]["location_type"]
  end

  def agents_emails
    @rdv["agents"].map { |agent| agent["email"] }
  end

  def owner
    if current_instructeur.email.in?(agents_emails)
      t('.you')
    else
      agents_emails.join(", ")
    end
  end

  def icon_class
    case location_type
    when "phone"
      "fr-icon-phone-fill"
    when "visio"
      "fr-icon-vidicon-fill"
    when "home"
      "fr-icon-home-4-fill"
    end
  end
end
