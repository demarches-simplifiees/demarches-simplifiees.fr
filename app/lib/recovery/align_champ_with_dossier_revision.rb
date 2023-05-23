class Recovery::AlignChampWithDossierRevision
  def initialize(dossiers, progress: nil)
    @dossiers = dossiers
    @progress = progress
    @logs = []
  end

  attr_reader :logs

  def run(destroy_extra_champs: false)
    @logs = []
    bad_dossier_ids = find_broken_dossier_ids

    Dossier
      .where(id: bad_dossier_ids)
      .includes(:procedure, champs: { type_de_champ: :revisions })
      .find_each do |dossier|
        bad_champs = dossier.champs.filter { !dossier.revision_id.in?(_1.type_de_champ.revisions.ids) }
        bad_champs.each do |champ|
          type_de_champ = dossier.revision.types_de_champ.find { _1.stable_id == champ.stable_id }
          state = {
            champ_id: champ.id,
            champ_type_de_champ_id: champ.type_de_champ_id,
            dossier_id: dossier.id,
            dossier_revision_id: dossier.revision_id,
            procedure_id: dossier.procedure.id
          }
          if type_de_champ.present?
            logs << state.merge(status: :updated, type_de_champ_id: type_de_champ.id)
            champ.update_column(:type_de_champ_id, type_de_champ.id)
          else
            logs << state.merge(status: :not_found)
            champ.destroy! if destroy_extra_champs
          end
        end
      end
  end

  def find_broken_dossier_ids
    bad_dossier_ids = []

    @dossiers.in_batches(of: 15_000) do |dossiers|
      dossier_ids_revision_ids = dossiers.pluck(:id, :revision_id)
      dossier_ids = dossier_ids_revision_ids.map(&:first)
      dossier_ids_type_de_champ_ids = Champ.where(dossier_id: dossier_ids).pluck(:dossier_id, :type_de_champ_id)
      type_de_champ_ids = dossier_ids_type_de_champ_ids.map(&:second).uniq
      revision_ids_by_type_de_champ_id = ProcedureRevisionTypeDeChamp
        .where(type_de_champ_id: type_de_champ_ids)
        .pluck(:type_de_champ_id, :revision_id)
        .group_by(&:first).transform_values { _1.map(&:second).uniq }

      type_de_champ_ids_by_dossier_id = dossier_ids_type_de_champ_ids
        .group_by(&:first)
        .transform_values { _1.map(&:second).uniq }

      bad_dossier_ids += dossier_ids_revision_ids.filter do |(dossier_id, revision_id)|
        type_de_champ_ids_by_dossier_id.fetch(dossier_id, []).any? do |type_de_champ_id|
          !revision_id.in?(revision_ids_by_type_de_champ_id.fetch(type_de_champ_id, []))
        end
      end.map(&:first)

      @progress.inc(dossiers.count) if @progress
    end

    @progress.finish if @progress

    bad_dossier_ids
  end
end
