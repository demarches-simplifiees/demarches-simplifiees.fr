# frozen_string_literal: true

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
    added_champs_root = fix_champs_root(dossier)
    added_champs_in_repetition = fix_champs_in_repetition(dossier)

    added_champs = added_champs_root + added_champs_in_repetition
    if !added_champs.empty?
      dossier.save!
      log_champs_added(dossier, added_champs)
      added_champs.size
    else
      0
    end
  end

  def fix_champs_root(dossier)
    champs_root, _ = dossier.champs.partition { _1.parent_id.blank? }
    expected_tdcs = dossier.revision.revision_types_de_champ.filter { _1.parent.blank? }.map(&:type_de_champ)

    expected_tdcs.filter { !champs_root.map(&:stable_id).include?(_1.stable_id) }
      .map do |missing_tdc|
                    champ_root_missing = missing_tdc.build_champ

                    dossier.champs_public << champ_root_missing
                    champ_root_missing
                  end
  end

  def fix_champs_in_repetition(dossier)
    champs_repetition, _ = dossier.champs.partition(&:repetition?)

    champs_repetition.flat_map do |champ_repetition|
      champ_repetition_missing = champ_repetition.rows.flat_map do |row|
        row_id = row.first.row_id
        expected_tdcs = dossier.revision.children_of(champ_repetition.type_de_champ)
        row_tdcs = row.map(&:type_de_champ)

        (expected_tdcs - row_tdcs).map do |missing_tdc|
          champ_repetition_missing = missing_tdc.build_champ(row_id: row_id)
          champ_repetition.champs << champ_repetition_missing
          champ_repetition_missing
        end
      end
    end
  end

  def log_champs_added(dossier, added_champs)
    app_traces = caller.reject { _1.match?(%r{/ruby/.+/gems/}) }.map { _1.sub(Rails.root.to_s, "") }

    payload = {
      message: "DataFixer::DossierChampsMissing",
      dossier_id: dossier.id,
      champs_ids: added_champs.map(&:id).join(","),
      caller: app_traces
    }

    logger = Lograge.logger || Rails.logger

    logger.info payload.to_json
  end
end
