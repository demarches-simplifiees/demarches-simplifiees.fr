module Manager
  class TeamAccountsController < Manager::ApplicationController
    def index
      @records_per_page = params[:records_per_page] || "10"
      resources = User.marked_as_team_account
        .order(created_at: :asc)
        .page(params[:_page])
        .per(@records_per_page)
      page = Administrate::Page::Collection.new(dashboard)

      render locals: {
        resources: resources,
        page: page,
        show_search_bar: false
      }
    end
  end
end
