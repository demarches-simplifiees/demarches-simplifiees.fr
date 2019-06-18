class DossierOperationLog < ApplicationRecord
  enum operation: {
    passer_en_instruction: 'passer_en_instruction',
    repasser_en_construction: 'repasser_en_construction',
    accepter: 'accepter',
    refuser: 'refuser',
    classer_sans_suite: 'classer_sans_suite',
    supprimer: 'supprimer',
    modifier_annotation: 'modifier_annotation',
    demander_un_avis: 'demander_un_avis'
  }

  belongs_to :dossier, -> { unscope(where: :hidden_at) }
  has_one_attached :serialized
  belongs_to :bill_signature, optional: true

  def self.create_and_serialize(params)
    dossier = params.fetch(:dossier)

    duree_conservation_dossiers = dossier.procedure.duree_conservation_dossiers_dans_ds
    keep_until = if duree_conservation_dossiers.present?
      if dossier.en_instruction_at
        dossier.en_instruction_at + duree_conservation_dossiers.months
      else
        dossier.created_at + duree_conservation_dossiers.months
      end
    end

    operation_log = new(operation: params.fetch(:operation),
      dossier_id: dossier.id,
      keep_until: keep_until,
      executed_at: Time.zone.now,
      automatic_operation: !!params[:automatic_operation])

    serialized = {
      operation: operation_log.operation,
      dossier_id: operation_log.dossier_id,
      author: self.serialize_author(params[:author]),
      subject: self.serialize_subject(params[:subject]),
      automatic_operation: operation_log.automatic_operation?,
      executed_at: operation_log.executed_at.iso8601
    }.compact.to_json

    operation_log.digest = Digest::SHA256.hexdigest(serialized)

    operation_log.serialized.attach(
      io: StringIO.new(serialized),
      filename: "operation-#{operation_log.digest}.json",
      content_type: 'application/json',
      # we don't want to run virus scanner on this file
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )

    operation_log.save!
  end

  def self.serialize_author(author)
    if author.nil?
      nil
    else
      OperationAuthorSerializer.new(author).as_json
    end
  end

  def self.serialize_subject(subject)
    if subject.nil?
      nil
    elsif !Flipflop.operation_log_serialize_subject?
      { id: subject.id }
    else
      case subject
      when Dossier
        DossierSerializer.new(subject).as_json
      when Champ
        ChampSerializer.new(subject).as_json
      when Avis
        AvisSerializer.new(subject).as_json
      end
    end
  end
end
