# frozen_string_literal: true

module Administrateurs
  class SourcesParticulierController < AdministrateurController
    before_action :retrieve_procedure

    def show
      @available_sources = sources_service.available_sources
    end

    def update
      if @procedure.update(api_particulier_sources: sources_params)
        redirect_to admin_procedure_api_particulier_sources_path(@procedure), notice: t('.sources_ok')
      else
        flash.now.alert = @procedure.errors.full_messages
        render :show
      end
    end

    private

    def sources_params
      requested_sources = params
        .with_defaults(api_particulier_sources: {})
        .to_unsafe_hash[:api_particulier_sources]

      sources_service.sanitize(requested_sources)
    end

    def sources_service
      @sources_service ||= APIParticulier::Services::SourcesService.new(@procedure)
    end
  end
end
