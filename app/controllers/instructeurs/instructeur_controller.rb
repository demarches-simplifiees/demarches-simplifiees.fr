module Instructeurs
  class InstructeurController < ApplicationController
    before_action :authenticate_instructeur!

    def nav_bar_profile
      :instructeur
    end
  end
end
