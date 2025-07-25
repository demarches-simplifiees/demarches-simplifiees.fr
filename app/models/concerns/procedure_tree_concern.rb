# frozen_string_literal: true

module ProcedureTreeConcern
  extend ActiveSupport::Concern

  def draft_public_tree
    DossierTree::Builder.procedure_tree(draft_public_coordinates, procedure: self)
  end

  def draft_private_tree
    DossierTree::Builder.procedure_tree(draft_private_coordinates, procedure: self)
  end

  private

  def draft_public_coordinates
    draft_revision.revision_types_de_champ.filter(&:public?)
  end

  def draft_private_coordinates
    draft_revision.revision_types_de_champ.filter(&:private?)
  end
end
