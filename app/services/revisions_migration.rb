class RevisionsMigration
  def self.add_revisions(procedure)
    if procedure.draft_revision.present?
      return false
    end

    procedure.draft_revision = procedure.revisions.create
    procedure.save!(validate: false)

    add_types_de_champs_to_revision(procedure, :types_de_champ)
    add_types_de_champs_to_revision(procedure, :types_de_champ_private)

    if !procedure.brouillon?
      published_revision = procedure.draft_revision

      procedure.draft_revision = procedure.create_new_revision
      procedure.published_revision = published_revision
      procedure.save!(validate: false)
    end

    true
  end

  def self.add_types_de_champs_to_revision(procedure, types_de_champ_scope)
    types_de_champ = procedure.send(types_de_champ_scope)
    types_de_champ.where(revision_id: nil).update_all(revision_id: procedure.draft_revision.id)

    types_de_champ.each.with_index do |type_de_champ, index|
      type_de_champ.types_de_champ.where(revision_id: nil).update_all(revision_id: procedure.draft_revision.id)
      procedure.draft_revision.send(:"revision_#{types_de_champ_scope}").create!(
        type_de_champ: type_de_champ,
        position: index
      )
    end
  end
end
