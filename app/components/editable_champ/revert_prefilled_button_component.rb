# frozen_string_literal: true

class EditableChamp::RevertPrefilledButtonComponent < ApplicationComponent
  def initialize(champ:)
    @champ = champ
  end

  def render?
    !@champ.private? && !@champ.instructeur_buffer_stream? && @champ.prefilled_value_modified?
  end

  def revert_path
    revert_prefill_champ_dossier_path(@champ.dossier, public_id: @champ.public_id)
  end
end
