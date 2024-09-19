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

  def revisions
    @revisions ||= ProcedureRevision.where(id: @dossiers.pluck(:revision_id).uniq)
      .includes(types_de_champ: { piece_justificative_template_attachment: :blob })
      .index_by(&:id)
  end

  # returns: { revision_id : { stable_id : position } }
  def positions
    @positions ||= revisions
      .transform_values { |revision| revision.revision_types_de_champ.map { [_1.stable_id, _1.position] }.to_h }
  end

  def load_dossiers(dossiers, pj_template: false)
    to_include = @includes_for_champ.dup
    to_include << [piece_justificative_file_attachments: :blob]

    all_champs = Champ
      .includes(to_include)
      .where(dossier_id: dossiers)
      .to_a

    children_champs, root_champs = all_champs.partition(&:child?)
    champs_by_dossier = root_champs.group_by(&:dossier_id)
    champs_by_dossier_by_parent = children_champs
      .group_by(&:dossier_id)
      .transform_values do |champs|
        champs.group_by(&:parent_id)
      end

    dossiers.each do |dossier|
      load_dossier(dossier, champs_by_dossier[dossier.id] || [], champs_by_dossier_by_parent[dossier.id] || {})
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

  def load_dossier(dossier, champs, children_by_parent = {})
    revision = revisions[dossier.revision_id]
    if revision.present?
      dossier.association(:revision).target = revision
    end

    champs_public, champs_private = champs.partition(&:public?)

    dossier.association(:champs).target = []
    load_champs(dossier, :champs_public, champs_public, dossier, children_by_parent)
    load_champs(dossier, :champs_private, champs_private, dossier, children_by_parent)

    # We need to do this because of the check on `Etablissement#champ` in
    # `Etablissement#libelle_for_export`. By assigning `nil` to `target` we mark association
    # as loaded and so the check on `Etablissement#champ` will not trigger n+1 query.
    if dossier.etablissement
      dossier.etablissement.association(:champ).target = nil
    end
  end

  def load_champs(parent, name, champs, dossier, children_by_parent)
    if champs.empty?
      parent.association(name).target = [] # tells to Rails association has been loaded
      return
    end

    champs.each do |champ|
      champ.association(:dossier).target = dossier

      if parent.is_a?(Champ)
        champ.association(:parent).target = parent
      end
    end

    dossier.association(:champs).target += champs

    parent.association(name).target = champs
      .filter { positions[dossier.revision_id][_1.stable_id].present? }
      .sort_by { [_1.row_id, positions[dossier.revision_id][_1.stable_id]] }

    # Load children champs
    champs.filter(&:block?).each do |parent_champ|
      champs = children_by_parent[parent_champ.id] || []
      parent_champ.association(:dossier).target = dossier

      load_champs(parent_champ, :champs, champs, dossier, children_by_parent)
    end
  end
end
