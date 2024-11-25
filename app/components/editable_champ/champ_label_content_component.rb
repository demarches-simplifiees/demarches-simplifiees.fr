# frozen_string_literal: true

class EditableChamp::ChampLabelContentComponent < ApplicationComponent
  include ApplicationHelper
  include Dsfr::InputErrorable

  attr_reader :attribute

  def initialize(form:, champ:, seen_at: nil)
    @form, @champ, @seen_at = form, champ, seen_at
    @attribute = :value
  end

  def highlight_if_unseen_class
    if highlight?
      'highlighted'
    end
  end

  def highlight?
    @champ.updated_at.present? && @seen_at&.<(@champ.updated_at)
  end

  def rebased?
    return false if @champ.rebased_at.blank?
    return false if @champ.rebased_at <= (@seen_at || @champ.updated_at)
    return false if !current_user.owns_or_invite?(@champ.dossier)
    return false if @champ.dossier.for_procedure_preview?

    true
  end
end
