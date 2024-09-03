# frozen_string_literal: true

module Manager
  class PublishedProceduresController < Manager::ApplicationController
    def index
      @records_per_page = params[:records_per_page] || "25"
      resources = Procedure
        .publiee
        .order(published_at: :desc)
        .page(params[:_page])
        .per(@records_per_page)
      page = Administrate::Page::Collection.new(dashboard)

      render locals: {
        resources: resources,
        page: page,
        show_search_bar: false,
        search_term: nil
      }
    end
  end
end
