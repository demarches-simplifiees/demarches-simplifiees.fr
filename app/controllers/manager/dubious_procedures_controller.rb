# frozen_string_literal: true

module Manager
  class DubiousProceduresController < Manager::ApplicationController
    def index
      raw_resources = DubiousProcedure.all
      resources = Kaminari.paginate_array(raw_resources).page(params[:_page]).per(records_per_page)
      page = Administrate::Page::Collection.new(dashboard)

      render locals: {
        resources: resources,
        page: page,
        show_search_bar: false,
        search_term: nil,
      }
    end
  end
end
