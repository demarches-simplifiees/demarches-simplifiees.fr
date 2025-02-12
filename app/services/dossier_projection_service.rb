# frozen_string_literal: true

class DossierProjectionService
  def self.project(dossiers_ids, columns)
    champ_columns, other_columns = columns.partition(&:champ_column?)

    to_include = other_columns.map(&:table).uniq.map(&:to_sym).map do |sym|
      case sym
      when :self
        nil
      when :user
        [:user, :individual]
      when :individual
        :individual
      when :etablissement
        :etablissement
      when :groupe_instructeur
        :groupe_instructeur
      when :followers_instructeurs
        :followers_instructeurs
      when :avis
        :avis
      when :dossier_labels
        :labels
      end
    end.flatten.uniq

    dossiers = Dossier.includes(:corrections, :pending_corrections, :traitements, *to_include).find(dossiers_ids)

    if champ_columns.any?
      stable_ids = champ_columns.map(&:stable_id)
      champs = Champ.where(dossier_id: dossiers_ids, stable_id: stable_ids, stream: 'main').includes(:piece_justificative_file_attachments).group_by(&:dossier_id)

      dossiers.each { |dossier| dossier.association(:champs).target = champs[dossier.id] || [] }
    end

    dossiers
  end
end
