class DossierPreloader
  DEFAULT_BATCH_SIZE = 2000

  def initialize(dossiers)
    @dossiers = dossiers
  end

  def in_batches(size = DEFAULT_BATCH_SIZE)
    dossiers = @dossiers.to_a
    dossiers.each_slice(size) { |slice| load_dossiers(slice) }
    dossiers
  end

  def all(pj_template: false)
    dossiers = @dossiers.to_a
    load_dossiers(dossiers, pj_template:)
    dossiers
  end

  def self.load_one(dossier, pj_template: false)
    DossierPreloader.new([dossier]).all(pj_template: pj_template).first
  end

  private

  # returns: { revision_id : { type_de_champ_id : position } }
  def positions
    @positions ||= ProcedureRevisionTypeDeChamp
      .where(revision_id: @dossiers.pluck(:revision_id).uniq)
      .select(:revision_id, :type_de_champ_id, :position)
      .group_by(&:revision_id)
      .transform_values do |coordinates|
        coordinates.index_by(&:type_de_champ_id).transform_values(&:position)
      end
  end

  def load_dossiers(dossiers, pj_template: false)
    to_include = [piece_justificative_file_attachments: :blob]

    if pj_template
      to_include << { type_de_champ: { piece_justificative_template_attachment: :blob } }
    else
      to_include << :type_de_champ
    end

    all_champs = Champ
      .includes(to_include)
      .where(dossier_id: dossiers)
      .to_a

    load_etablissements(all_champs)

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
  end

  def load_etablissements(champs)
    champs_siret = champs.filter(&:siret?)
    etablissements_by_id = Etablissement.where(id: champs_siret.map(&:etablissement_id).compact).index_by(&:id)
    champs_siret.each do |champ|
      etablissement = etablissements_by_id[champ.etablissement_id]
      champ.association(:etablissement).target = etablissement
      if etablissement
        etablissement.association(:champ).target = champ
      end
    end
  end

  def load_dossier(dossier, champs, children_by_parent = {})
    champs_public, champs_private = champs.partition(&:public?)

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
    champs.each do |champ|
      champ.association(:dossier).target = dossier

      if parent.is_a?(Champ)
        champ.association(:parent).target = parent
      end
    end

    parent.association(name).target = champs.sort_by do |champ|
      [champ.row, positions[dossier.revision_id][champ.type_de_champ_id]]
    end

    # Load children champs
    champs.filter(&:block?).each do |parent_champ|
      champs = children_by_parent[parent_champ.id] || []
      parent_champ.association(:dossier).target = dossier

      load_champs(parent_champ, :champs, champs, dossier, children_by_parent)
    end
  end
end
