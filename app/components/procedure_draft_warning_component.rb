# frozen_string_literal: true

class ProcedureDraftWarningComponent < ApplicationComponent
  attr_reader :revision
  attr_reader :current_administrateur
  attr_reader :extra_class_names

  def initialize(revision:, current_administrateur:, extra_class_names: nil)
    @revision = revision
    @current_administrateur = current_administrateur
    @extra_class_names = extra_class_names
  end

  def render?
    revision.draft?
  end

  def admin?
    current_administrateur.present? && revision.procedure.administrateurs.include?(current_administrateur)
  end
end
