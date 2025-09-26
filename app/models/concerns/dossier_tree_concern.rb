# frozen_string_literal: true

module DossierTreeConcern
  extend ActiveSupport::Concern

  def public_tree(profile: nil)
    dossier_trees(profile, []).first
  end

  def private_tree(profile: nil)
    dossier_trees(profile, private_coordinates).second
  end

  private

  def dossier_trees(profile, private_coordinates)
    DossierTree::Builder.dossier_trees(public_coordinates, private_coordinates, dossier: self, profile:)
  end

  def public_coordinates
    coordinates = revision.revision_types_de_champ.filter(&:public?)
    if submitted_revision_id.present? && submitted_revision_id != revision_id
      coordinate_stable_ids = coordinates.to_set(&:stable_id)
      submitted_coordinates = submitted_revision.revision_types_de_champ
        .filter { _1.public? && !coordinate_stable_ids.member?(_1.stable_id) }

      coordinates + submitted_coordinates
    else
      coordinates
    end
  end

  def private_coordinates
    revision.revision_types_de_champ.filter(&:private?)
  end
end
