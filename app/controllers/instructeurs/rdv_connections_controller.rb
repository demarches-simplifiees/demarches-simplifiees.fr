# frozen_string_literal: true

module Instructeurs
  class RdvConnectionsController < InstructeurController
    def index
      @rdv_email = RdvService.new(rdv_connection: current_instructeur.rdv_connection).get_account_info["email"]
    end
  end
end
