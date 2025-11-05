# frozen_string_literal: true

module Manager
  class TeamAccountsController < Manager::ApplicationController
    def index
      @records_per_page = params[:records_per_page] || "10"

      resources = Administrateur
        .where(user: { team_account: true })
        .order(created_at: :asc)
        .page(params[:_page])
        .per(@records_per_page)

      resources.each do |resource|
        def resource.procedures_count
          procedures.with_discarded.count
        end

        def resource.last_sign_in_at = user.last_sign_in_at
        def resource.current_sign_in_at = user.current_sign_in_at
      end

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
