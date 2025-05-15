# frozen_string_literal: true

class Procedure::ServiceListContactComponent < ApplicationComponent
  attr_reader :dossier, :faq_link, :contact_link, :email, :telephone, :telephone_url, :other_contact_info, :horaires

  def initialize(service_or_contact_information:, dossier:)
    @dossier = dossier
    @faq_link = service_or_contact_information.respond_to?(:faq_link) ? service_or_contact_information.faq_link : nil
    @contact_link = service_or_contact_information.respond_to?(:contact_link) ? service_or_contact_information.contact_link : nil
    @email = service_or_contact_information.email
    @telephone = service_or_contact_information.telephone
    @telephone_url = service_or_contact_information.telephone_url
    @other_contact_info = service_or_contact_information.respond_to?(:other_contact_info) ? service_or_contact_information.other_contact_info : nil
    @horaires = service_or_contact_information.horaires
  end
end
