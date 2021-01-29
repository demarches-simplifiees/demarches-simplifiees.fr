class PiecesJustificativesService
  def self.liste_pieces_justificatives(dossier)
    pjs_champs = pjs_for_champs(dossier)
    pjs_commentaires = pjs_for_commentaires(dossier)
    pjs_dossier = pjs_for_dossier(dossier)

    (pjs_champs + pjs_commentaires + pjs_dossier)
      .filter(&:attached?)
  end

  def self.pieces_justificatives_total_size(dossier)
    liste_pieces_justificatives(dossier)
      .sum(&:byte_size)
  end

  def self.zip_entries(dossier)
    pjs = champs_zip_entries(dossier) + commentaires_zip_entries(dossier) + dossier_zip_entries(dossier)
    index = {}
    pjs.map do |blob, filename|
      [
        blob,
        normalized_filename(index, blob, filename)
      ]
    end
  end

  def self.serialize_types_de_champ_as_type_pj(revision)
    tdcs = revision.types_de_champ.filter { |type_champ| type_champ.old_pj.present? }
    tdcs.map.with_index do |type_champ, order_place|
      description = type_champ.description
      if /^(?<original_description>.*?)(?:[\r\n]+)Récupérer le formulaire vierge pour mon dossier : (?<lien_demarche>http.*)$/m =~ description
        description = original_description
      end
      {
        id: type_champ.old_pj[:stable_id],
        libelle: type_champ.libelle,
        description: description,
        order_place: order_place,
        lien_demarche: lien_demarche
      }
    end
  end

  def self.serialize_champs_as_pjs(dossier)
    dossier.champs.filter { |champ| champ.type_de_champ.old_pj }.map do |champ|
      {
        created_at: champ.created_at&.in_time_zone('UTC'),
        type_de_piece_justificative_id: champ.type_de_champ.old_pj[:stable_id],
        content_url: champ.for_api,
        user: champ.dossier.user
      }
    end
  end

  private

  def self.normalized_filename(index, attachment, filename)
    # PF Code
    # timestamp is replaced by a postfix (-2,-3,-4) which is added only on collapsing filenames (rare)

    # first sanitize the filename as it is based on fields names.
    sanitized = filename.to_s.split('/').map do |f|
      ActiveStorage::Filename.new(f).sanitized
    end
    # prefix with the folder
    folder = self.folder(attachment)
    filename = [folder, *sanitized].join('/')
    # add optional -Number if filename collide with another
    i = index[filename]
    if i.present?
      i = (index[filename] += 1)
      filename.sub(/(\.[^.]+)?$/, "-#{i}\\1")
    else
      index[filename] = 1
      filename
    end
  end

  def self.folder(attachment)
    case attachment.record_type
    when 'Dossier'
      'dossier'
    when 'DossierOperationLog', 'BillSignature'
      'horodatage'
    when 'Commentaire'
      'messagerie'
    else
      'pieces_justificatives'
    end
  end

  def self.pjs_champs(dossier)
    allowed_champs = dossier.champs + dossier.champs_private

    allowed_child_champs = allowed_champs
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:repetition) }
      .flat_map(&:champs)

    (allowed_champs + allowed_child_champs)
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:piece_justificative) }
  end

  def self.pjs_for_champs(dossier)
    pjs_champs(dossier).map(&:piece_justificative_file)
  end

  def self.pjs_for_commentaires(dossier)
    dossier
      .commentaires
      .map(&:piece_jointe)
  end

  def self.pjs_for_dossier(dossier)
    bill_signatures = dossier.dossier_operation_logs.map(&:bill_signature).compact.uniq

    [
      dossier.justificatif_motivation,
      dossier.attestation&.pdf,
      dossier.etablissement&.entreprise_attestation_sociale,
      dossier.etablissement&.entreprise_attestation_fiscale,
      dossier.dossier_operation_logs.map(&:serialized),
      bill_signatures.map(&:serialized),
      bill_signatures.map(&:signature)
    ].flatten.compact
  end

  def self.dossier_zip_entries(dossier)
    pjs_zip_entries(pjs_for_dossier(dossier))
  end

  def self.commentaires_zip_entries(dossier)
    pjs_zip_entries(pjs_for_commentaires(dossier))
  end

  def self.champs_zip_entries(dossier)
    pjs_champs(dossier)
      .filter { |champ| champ.piece_justificative_file.attached? }
      .map { |champ| [champ.piece_justificative_file, pieces_justificative_filename(champ)] }
  end

  def self.pieces_justificative_filename(champ)
    folder = champ.type_de_champ.parent ? "#{champ.type_de_champ.parent.libelle}/" : ""
    "#{folder}#{champ.type_de_champ.libelle}-#{champ.piece_justificative_file.filename}"
  end

  def self.pjs_zip_entries(pjs)
    pjs.filter(&:attached?).map { |c| [c, c.filename] }
  end
end
