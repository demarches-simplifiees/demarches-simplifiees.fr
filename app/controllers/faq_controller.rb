# frozen_string_literal: true

class FAQController < ApplicationController
  before_action :load_faq_data, only: :show

  def index
    @faqs = loader_service.all
  end

  def show
    @renderer = Redcarpet::Markdown.new(Redcarpet::TrustedRenderer.new(view_context), autolink: true)

    @siblings = loader_service.faqs_for_category(@metadata[:category])
  end

  private

  def loader_service
    @loader_service ||= begin
                          substitutions = {
                            application_base_url: Current.application_base_url,
                            application_name: Current.application_name,
                            contact_email: Current.contact_email
                          }

                          FAQsLoaderService.new(substitutions)
                        end
  end

  def load_faq_data
    path = "#{params[:category]}/#{params[:slug]}"
    faq_data = loader_service.find(path)

    @content = faq_data.content
    @metadata = faq_data.front_matter.symbolize_keys
  rescue KeyError
    raise ActionController::RoutingError.new("FAQ not found: #{path}")
  end
end
