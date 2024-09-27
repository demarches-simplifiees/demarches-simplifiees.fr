# frozen_string_literal: true

class DossierPreloader
  DEFAULT_BATCH_SIZE = 2000

  def initialize(dossiers, includes_for_champ: [], includes_for_etablissement: [])
    @dossiers = dossiers
    @includes_for_etablissement = includes_for_etablissement
    @includes_for_champ = includes_for_champ
  end

  def in_batches(size = DEFAULT_BATCH_SIZE)
    dossiers = @dossiers.to_a
    dossiers.each_slice(size) { |slice| load_dossiers(slice) }
    dossiers
  end

  def in_batches_with_block(size = DEFAULT_BATCH_SIZE, &block)
    @dossiers.in_batches(of: size) do |batch|
      data = Dossier.where(id: batch.ids).includes(:individual, :traitement, :etablissement, user: :france_connect_informations, avis: :expert, commentaires: [:instructeur, :expert])

      dossiers = data.to_a
      load_dossiers(dossiers)
      yield(dossiers)
    end
  end

  def all(pj_template: false)
    dossiers = @dossiers.to_a
    load_dossiers(dossiers, pj_template:)
    dossiers
  end

  def self.load_one(dossier, pj_template: false)
    DossierPreloader.new([dossier]).all(pj_template:).first
  end

  private

  def revisions(pj_template: false)
    @revisions ||= ProcedureRevision.where(id: @dossiers.pluck(:revision_id).uniq)
      .includes(types_de_champ: pj_template ? { piece_justificative_template_attachment: :blob } : [])
      .index_by(&:id)
  end

  def load_dossiers(dossiers, pj_template: false)
    to_include = @includes_for_champ.dup
    to_include << [piece_justificative_file_attachments: :blob]

    all_champs = Champ
      .includes(to_include)
      .where(dossier_id: dossiers)
      .to_a

    champs_by_dossier = all_champs.group_by(&:dossier_id)

    dossiers.each do |dossier|
      load_dossier(dossier, champs_by_dossier[dossier.id] || [], pj_template:)
    end

    load_etablissements(all_champs)
  end

  def load_etablissements(champs)
    to_include = @includes_for_etablissement.dup
    champs_siret = champs.filter(&:siret?)
    etablissements_by_id = Etablissement.includes(to_include).where(id: champs_siret.map(&:etablissement_id).compact).index_by(&:id)
    champs_siret.each do |champ|
      etablissement = etablissements_by_id[champ.etablissement_id]
      champ.association(:etablissement).target = etablissement
      if etablissement
        etablissement.association(:champ).target = champ
      end
    end
  end

  def load_dossier(dossier, champs, pj_template: false)
    revision = revisions(pj_template:)[dossier.revision_id]
    if revision.present?
      dossier.association(:revision).target = revision
    end
    dossier.association(:champs).target = champs
    dossier.association(:champs_public).target = dossier.project_champs_public
    dossier.association(:champs_private).target = dossier.project_champs_private

    # remove once parent_id is deprecated
    champs_by_parent_id = champs.group_by(&:parent_id)

    champs.each do |champ|
      champ.association(:dossier).target = dossier

      # remove once parent_id is deprecated
      if champ.repetition?
        children = champs_by_parent_id.fetch(champ.id, [])
        children.each do |child|
          child.association(:parent).target = champ
        end
        champ.association(:champs).target = children
      end
    end

    # We need to do this because of the check on `Etablissement#champ` in
    # `Etablissement#libelle_for_export`. By assigning `nil` to `target` we mark association
    # as loaded and so the check on `Etablissement#champ` will not trigger n+1 query.
    if dossier.etablissement
      dossier.etablissement.association(:champ).target = nil
    end
  end
end
