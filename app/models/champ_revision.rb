class ChampRevision < ApplicationRecord
  belongs_to :champ, inverse_of: :champ_revisions, optional: false
  belongs_to :instructeur, inverse_of: false, optional: false
  belongs_to :etablissement, optional: true, dependent: :destroy

  def self.create_or_update_revision(champ, instructeur_id)
    champ_revision = where(champ:).order(:id).last
    if champ_revision.nil? || champ_revision.instructeur_id != instructeur_id || 4.minutes.ago.after?(champ_revision.updated_at)
      champ_revision = new(champ:, instructeur_id:)
    end

    ['data', 'etablissement_id', 'external_id', 'fetch_external_data_exceptions', 'value', 'value_json'].each do |attrbt|
      champ_revision.send("#{attrbt}=", champ.attributes[attrbt])
    end

    if ['Champs::TitreIdentiteChamp', 'Champs::PieceJustificativeChamp'].include?(champ.type)
      champ_revision.value ||= champ.piece_justificative_file.map(&:filename).join(', ')
    end

    champ_revision.save
  end

  def rebuild_champ
    ['data', 'etablissement_id', 'external_id', 'fetch_external_data_exceptions', 'value', 'value_json'].each do |attrbt|
      champ.send("#{attrbt}=", self.attributes[attrbt])
    end
    champ
  end

  def self.create_or_update_revision_if_needed(dossier, champs_private_attributes_params, instructeur_id)
    revised_champs = if champs_private_attributes_params.values.filter { _1.key?(:with_public_id) }.empty?
                       champ_ids = champs_private_attributes_params.values.map { _1[:id] }.compact.map(&:to_i)
                       dossier.champs.filter(&:private?).filter { _1.id.in?(champ_ids) }
                     else
                       champ_public_ids = champs_private_attributes_params.keys
                       dossier.champs.filter(&:private?).filter { _1.public_id.in?(champ_public_ids) }
                     end.filter { _1.previous_changes.present? }

    revised_champs.each do |champ|
      create_or_update_revision(champ, instructeur_id)
    end
  end
end
