module DossierChampHelpers
  def dossier_get_readable_champ(dossier, stable_id, row_id)
    type_de_champ = dossier.find_type_de_champ_by_stable_id(stable_id)
    dossier.champs.reload
    dossier.project_champ(type_de_champ, row_id)
  end

  def dossier_get_writable_champ(dossier, stable_id, row_id)
    type_de_champ = dossier.find_type_de_champ_by_stable_id(stable_id)
    dossier.champ_for_update(type_de_champ, row_id, updated_by: dossier.user.email)
  end

  def dossier_get_readable_public_champ_at(dossier, index)
    stable_id = dossier.revision.types_de_champ_public[index].stable_id
    dossier_get_readable_champ(dossier, stable_id, nil)
  end

  def dossier_get_writable_public_champ_at(dossier, index)
    stable_id = dossier.revision.types_de_champ_public[index].stable_id
    dossier_get_writable_champ(dossier, stable_id, nil)
  end

  def dossier_get_readable_private_champ_at(dossier, index)
    stable_id = dossier.revision.types_de_champ_private[index].stable_id
    dossier_get_readable_champ(dossier, stable_id, nil)
  end

  def dossier_get_writable_private_champ_at(dossier, index)
    stable_id = dossier.revision.types_de_champ_private[index].stable_id
    dossier_get_writable_champ(dossier, stable_id, nil)
  end
end
