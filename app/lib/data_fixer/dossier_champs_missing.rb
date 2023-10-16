# some race condition (regarding double submit of dossier.passer_en_construction!) might remove champs
#   until now we haven't decided to push a stronger fix than an UI change
#   so we might have to recreate some deleted champs and notify administration
class DataFixer::DossierChampsMissing
  def fix
    fixed_on_origin = apply_fix(@original_dossier)

    fixed_on_other = Dossier.where(editing_fork_origin_id: @original_dossier.id)
      .map(&method(:apply_fix))

    [fixed_on_origin, fixed_on_other.sum].sum
  end

  private

  attr_reader :original_dossier

  def initialize(dossier:)
    @original_dossier = dossier
  end

  def apply_fix(dossier)
    dossier_champs = dossier.champs_public.includes(:type_de_champ)
    revision_type_de_champ = TypeDeChamp.joins(:revision_type_de_champ).where(revision_type_de_champ: { revision: dossier.revision })

    dossier_tdc_stable_ids = dossier_champs.map(&:type_de_champ).map(&:stable_id)

    missing_tdcs = revision_type_de_champ.filter { !dossier_tdc_stable_ids.include?(_1.stable_id) }
    missing_tdcs.map do |missing_champ|
      dossier.champs_public << missing_champ.build_champ
    end

    if !missing_tdcs.empty?
      dossier.save!
      missing_tdcs.size
    else
      0
    end
  end
end
