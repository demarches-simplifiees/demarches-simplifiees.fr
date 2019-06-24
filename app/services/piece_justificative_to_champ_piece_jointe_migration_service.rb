require Rails.root.join("lib", "tasks", "task_helper")

class PieceJustificativeToChampPieceJointeMigrationService
  def initialize(**params)
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def ensure_correct_storage_configuration!
    storage_service.ensure_openstack_copy_possible!(PieceJustificativeUploader)
  end

  def procedures_with_pjs_in_range(ids_range)
    procedures_with_pj = Procedure.unscope(where: :hidden_at).joins(:types_de_piece_justificative).distinct
    procedures_with_pj.where(id: ids_range)
  end

  def number_of_champs_to_migrate(procedure)
    (procedure.types_de_piece_justificative.count + 1) * procedure.dossiers.unscope(where: :hidden_at).count
  end

  def convert_procedure_pjs_to_champ_pjs(procedure, &progress)
    types_de_champ_pj = PiecesJustificativesService.types_pj_as_types_de_champ(procedure)
    populate_champs_pjs!(procedure, types_de_champ_pj, &progress)

    # Only destroy the old types PJ once everything has been safely migrated to
    # champs PJs.

    # First destroy the individual PJ champs on all dossiers.
    # It will cascade and destroy the PJs, and delete the linked objects from remote storage.
    procedure.dossiers.unscope(where: :hidden_at).includes(:champs).find_each do |dossier|
      destroy_pieces_justificatives(dossier)
    end

    # Now we can destroy the type de champ themselves,
    # without cascading the timestamp update on all attached dossiers.
    procedure.types_de_piece_justificative.destroy_all
  end

  def storage_service
    @storage_service ||= CarrierwaveActiveStorageMigrationService.new
  end

  def populate_champs_pjs!(procedure, types_de_champ_pj, &progress)
    procedure.types_de_champ += types_de_champ_pj

    # Unscope to make sure all dossiers are migrated, even the soft-deleted ones
    procedure.dossiers.unscope(where: :hidden_at).includes(:champs).find_each do |dossier|
      migrate_dossier!(dossier, types_de_champ_pj, &progress)
    end

  rescue StandardError, SignalException
    # If anything goes wrong, we roll back the migration by destroying the newly created
    # types de champ, champs blobs and attachments.
    rake_puts "Error received. Rolling back migration of procedure #{procedure.id}…"
    rollback_migration!(types_de_champ_pj)
    rake_puts "Migration of procedure #{procedure.id} rolled back."

    # Reraise the exception to abort the migration.
    raise
  end

  def migrate_dossier!(dossier, types_de_champ_pj)
    # Add the new pieces justificatives champs to the dossier
    champs_pj = types_de_champ_pj.map(&:build_champ)
    preserving_updated_at(dossier) do
      dossier.champs += champs_pj
    end

    # Copy the dossier old pieces jointes to the new champs
    # (even if the champs already existed, so that we ensure a clean state)
    champs_pj.each do |champ|
      type_pj_id = champ.type_de_champ.old_pj&.fetch('stable_id', nil)
      pj = dossier.retrieve_last_piece_justificative_by_type(type_pj_id)

      if pj.present?
        preserving_updated_at(dossier) do
          convert_pj_to_champ!(pj, champ)
        end

        champ.update_columns(
          updated_at: pj.updated_at,
          created_at: pj.created_at
        )
      else
        champ.update_columns(
          created_at: dossier.created_at,
          # Set an updated_at date that won't cause notifications to appear
          # on gestionnaires' dashboard.
          updated_at: dossier.created_at
        )
      end

      yield if block_given?
    end
  end

  def convert_pj_to_champ!(pj, champ)
    actual_file_exists = pj.content.file.send(:file)
    if actual_file_exists
      blob = make_blob(pj)

      # Upload the file before creating the attachment to make sure MIME type
      # identification doesn’t fail.
      storage_service.copy_from_carrierwave_to_active_storage!(pj.content.path, blob)
      attachment = storage_service.make_attachment(champ, 'piece_justificative_file', blob)

    else
      make_empty_blob(pj)
      rake_puts "Notice: attached file for champ #{champ.id} not found. An empty blob has been attached instead."
    end

    # By reloading, we force ActiveStorage to look at the attachment again, and see
    # that one exists now. We do this so that, if we need to roll back and destroy the champ,
    # the blob, the attachment and the actual file on OpenStack also get deleted.
    champ.reload
  rescue StandardError, SignalException
    # Destroy partially attached object that the more general rescue in `populate_champs_pjs!`
    # might not be able to handle.

    if blob&.key.present?
      begin
        storage_service.delete_from_active_storage!(blob)
      rescue => e
        # The cleanup attempt failed, perhaps because the object had not been
        # successfully copied to the Active Storage bucket yet.
        # Continue trying to clean up the rest anyway.
        pp e
      end
    end

    blob&.destroy
    attachment&.destroy
    champ.reload

    # Reraise the exception to abort the migration.
    raise
  end

  def rollback_migration!(types_de_champ_pj)
    types_de_champ_pj.each do |type_champ|
      # First destroy all the individual champs on dossiers
      type_champ.champ.each do |champ|
        begin
          destroy_champ_pj(Dossier.unscope(where: :hidden_at).find(champ.dossier_id), champ)
        rescue => e
          rake_puts e
          rake_puts "Rolling back of champ #{champ.id} failed. Continuing to roll back…"
        end
      end
      # Now we can destroy the type de champ itself,
      # without cascading the timestamp update on all attached dossiers.
      type_champ.reload.destroy
    end
  end

  def make_blob(pj)
    storage_service.make_blob(pj.content, pj.updated_at.iso8601, filename: pj.original_filename)
  end

  def make_empty_blob(pj)
    storage_service.make_empty_blob(pj.content, pj.updated_at.iso8601, filename: pj.original_filename)
  end

  def preserving_updated_at(model)
    original_modification_date = model.updated_at
    begin
      yield
    ensure
      model.update_column(:updated_at, original_modification_date)
    end
  end

  def destroy_pieces_justificatives(dossier)
    preserving_updated_at(dossier) do
      dossier.pieces_justificatives.destroy_all
    end
  end

  def destroy_champ_pj(dossier, champ)
    preserving_updated_at(dossier) do
      champ.piece_justificative_file.purge
      champ.destroy
    end
  end
end
