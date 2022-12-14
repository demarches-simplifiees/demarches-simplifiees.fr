class EditableChamp::PieceJustificativeComponent < EditableChamp::EditableChampBaseComponent
  def view_as
    if @champ.dossier.brouillon?
      :link
    else
      :download
    end
  end

  def user_can_destroy?
    !@champ.mandatory? || @champ.dossier.brouillon?
  end

  def user_can_replace?
    @champ.mandatory? && @champ.dossier.en_construction?
  end

  def max
    [true, nil].include?(@champ.procedure&.piece_justificative_multiple?) ? Attachment::MultipleComponent::DEFAULT_MAX_ATTACHMENTS : 1
  end
end
