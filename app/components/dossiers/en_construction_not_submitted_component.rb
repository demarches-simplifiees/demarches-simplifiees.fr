# frozen_string_literal: true

class Dossiers::EnConstructionNotSubmittedComponent < ApplicationComponent
  attr_reader :dossier
  attr_reader :user

  def initialize(dossier:, user:)
    @dossier = dossier
    @user = user
  end

  def render?
    @dossier.user_buffer_changes?
  end
end
