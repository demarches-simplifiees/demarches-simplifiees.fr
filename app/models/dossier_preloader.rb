class DossierPreloader
  DEFAULT_BATCH_SIZE = 2000

  def initialize(dossiers, includes_for_dossier: [], includes_for_etablissement: [])
    @dossiers = dossiers
    @includes_for_etablissement = includes_for_etablissement
    @includes_for_dossier = includes_for_dossier
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

  def load_dossiers(dossiers, pj_template: false)
    to_include = @includes_for_dossier.dup
    to_include << [piece_justificative_file_attachments: :blob]

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
    champs_by_dossier = all_champs.group_by(&:dossier_id)

    dossiers.each do |dossier|
      load_dossier(dossier, champs_by_dossier[dossier.id] || [])
    end
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

  def load_dossier(dossier, champs)
    children_champs, root_champs = champs.partition(&:child?)
    champs_public, champs_private = root_champs.partition(&:public?)
    children_champs_public, children_champs_private = children_champs.partition(&:public?)

    dossier.association(:champs).target = champs
    dossier.association(:champs_public).target = champs_public
    dossier.association(:champs_public_all).target = champs_public + children_champs_public
    dossier.association(:champs_private).target = champs_private
    dossier.association(:champs_private_all).target = champs_private + children_champs_private

    champs.each do |champ|
      champ.association(:dossier).target = dossier
    end

    # We need to do this because of the check on `Etablissement#champ` in
    # `Etablissement#libelle_for_export`. By assigning `nil` to `target` we mark association
    # as loaded and so the check on `Etablissement#champ` will not trigger n+1 query.
    if dossier.etablissement
      dossier.etablissement.association(:champ).target = nil
    end
  end
end
