module DossierChampsConcern
  extend ActiveSupport::Concern

  def champs_for_revision(scope: nil, root: false)
    champs_index = champs.group_by(&:stable_id)
      # Due to some bad data we can have multiple copies of the same champ. Ignore extra copy.
      .transform_values { _1.sort_by(&:id).uniq(&:row_id) }

    if scope.is_a?(TypeDeChamp)
      revision
        .children_of(scope)
        .flat_map { champs_index[_1.stable_id] || [] }
        .filter(&:child?) # TODO: remove once bad data (child champ without a row id) is cleaned
    else
      revision
        .types_de_champ_for(scope:, root:)
        .flat_map { champs_index[_1.stable_id] || [] }
    end
  end

  # Get all the champs values for the types de champ in the final list.
  # Dossier might not have corresponding champ – display nil.
  # To do so, we build a virtual champ when there is no value so we can call for_export with all indexes
  def champs_for_export(types_de_champ, row_id = nil)
    types_de_champ.flat_map do |type_de_champ|
      champ = champ_for_export(type_de_champ, row_id)
      type_de_champ.libelles_for_export.map do |(libelle, path)|
        [libelle, champ&.for_export(path)]
      end
    end
  end

  def project_champ(type_de_champ, row_id)
    champ = champs_by_public_id[type_de_champ.public_id(row_id)]
    if champ.nil?
      type_de_champ.build_champ(dossier: self, row_id:)
    else
      champ
    end
  end

  private

  def champs_by_public_id
    @champs_by_public_id ||= champs.sort_by(&:id).index_by(&:public_id)
  end

  def champ_for_export(type_de_champ, row_id)
    champ = champs_by_public_id[type_de_champ.public_id(row_id)]
    if champ.blank? || !champ.visible?
      nil
    else
      champ
    end
  end
end
