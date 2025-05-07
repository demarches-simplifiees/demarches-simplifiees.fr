# frozen_string_literal: true

class Procedure::ServiceListContactComponent < ApplicationComponent
  attr_reader :dossier, :faq_link, :contact_link, :email, :telephone, :telephone_url, :other_contact_info, :horaires

  def initialize(service:, dossier:)
    @dossier = dossier

    @faq_link = service.is_a?(Service) ? service.faq_link : nil
    @contact_link = service.is_a?(Service) ? service&.contact_link : nil
    @email = service.email
    @telephone = service.telephone
    @telephone_url = service.telephone_url
    @other_contact_info = service.is_a?(Service) ? service.other_contact_info : nil
    @horaires = service.horaires
  end
end
