module Users
  class PrefillsController < ApplicationController
    layout 'procedure_context'

    before_action :retrieve_dossier
    before_action :check_prefill_token
    before_action :set_dossier_ownership,          if:     -> { user_signed_in? && @dossier.orphan? }
    before_action :check_dossier_ownership,        if:     -> { user_signed_in? }
    before_action :redirect_to_brouillon,          if:     -> { @dossier.owned_by?(current_user) }
    before_action :come_back_after_authentication, unless: -> { user_signed_in? }

    def show
    end

    private

    # The dossier is not owned yet, and the user is signed in: they become the new owner
    def set_dossier_ownership
      @dossier.update!(user: current_user)
    end

    # The dossier is owned by another user: raise an exception
    def check_dossier_ownership
      raise ActiveRecord::RecordNotFound unless @dossier.owned_by?(current_user)
    end

    # The current user is already the dossier owner: let's go
    def redirect_to_brouillon
      redirect_to brouillon_dossier_path(@dossier)
    end

    # When the user is not signed in: they can sign in / sign up / france connect and come back here afterwards
    def come_back_after_authentication
      store_location_for(:user, prefill_path(@dossier, token: @dossier.prefill_token))
    end

    def check_prefill_token
      raise ActiveRecord::RecordNotFound if params[:token].blank? || @dossier.prefill_token != params[:token]
    end

    def retrieve_dossier
      @dossier = Dossier.state_brouillon.prefilled.find(params[:id])
    end
  end
end
