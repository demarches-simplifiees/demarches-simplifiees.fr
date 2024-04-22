# frozen_string_literal: true

class FAQController < ApplicationController
  before_action :load_faq_data, only: :show

  def show
    @renderer = Redcarpet::Markdown.new(
      Redcarpet::BareRenderer.new(class_names_map: { list: 'fr-ol-content--override' })
    )
  end

  private

  def loader_service
    @loader_service ||= FAQsLoaderService.new
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
