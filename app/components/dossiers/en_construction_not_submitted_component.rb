# frozen_string_literal: true

class Dossiers::EnConstructionNotSubmittedComponent < ApplicationComponent
  attr_reader :dossier
  attr_reader :user

  def initialize(dossier:, user:)
    @dossier = dossier
    @user = user

    @fork = @dossier.find_editing_fork(user, rebase: false)
  end

  def render?
    @fork&.forked_with_changes?
  end
end
