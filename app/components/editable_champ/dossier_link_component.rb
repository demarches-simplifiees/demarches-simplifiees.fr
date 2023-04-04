class EditableChamp::DossierLinkComponent < EditableChamp::EditableChampBaseComponent
  def dossier
    @dossier ||= @champ.blank? ? nil : Dossier.visible_by_administration.find_by(id: @champ.to_s)
  end
end
