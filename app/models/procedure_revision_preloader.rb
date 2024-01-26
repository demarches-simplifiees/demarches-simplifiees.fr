class ProcedureRevisionPreloader
  def initialize(revisions)
    @revisions = revisions
  end

  def all
    revisions = @revisions.to_a
    load_revisions(revisions)
  end

  def self.load_one(revision)
    ProcedureRevisionPreloader.new([revision]).all.first
  end

  private

  def load_revisions(revisions)
    revisions.map { load_procedure_revision_types_de_champ(_1) }
  end

  def load_procedure_revision_types_de_champ(revision)
    prtdcs = ProcedureRevisionTypeDeChamp
      .where(revision:)
      .includes(type_de_champ: { notice_explicative_attachment: :blob, piece_justificative_template_attachment: :blob })
      .order(:position, :id)
      .to_a

    prtdcs.each do |prtdc|
      prtdc.association(:revision).target = revision
      prtdc.association(:procedure).target = revision.procedure
    end

    assign_revision_type_de_champ(revision, prtdcs)
    assign_revision_type_de_champ_public(revision, prtdcs)
    assign_revision_type_de_champ_private(revision, prtdcs)
  end

  def assign_revision_type_de_champ(revision, prtdcs)
    revision.association(:revision_types_de_champ).target = prtdcs
    revision.association(:types_de_champ).target = revision.revision_types_de_champ.map(&:type_de_champ)
  end

  def assign_revision_type_de_champ_private(revision, prtdcs)
    revision.association(:revision_types_de_champ_private).target = prtdcs.filter do
      _1.parent_id.nil? && _1.type_de_champ.private?
    end
    revision.association(:types_de_champ_private).target = revision.revision_types_de_champ_private.map(&:type_de_champ)
  end

  def assign_revision_type_de_champ_public(revision, prtdcs)
    revision.association(:revision_types_de_champ_public).target = prtdcs.filter do
      _1.parent_id.nil? && _1.type_de_champ.public?
    end
    revision.association(:types_de_champ_public).target = revision.revision_types_de_champ_public.map(&:type_de_champ)
  end
end
