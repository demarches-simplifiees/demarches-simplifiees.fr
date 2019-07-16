# Note: this class uses a `synthetic_state` for Dossier, that diverges from the standard state:
#   - 'termine' is the synthetic_state for all dossiers
#     whose state is 'accepte', 'refuse' or 'sans_suite',
#     even when `archive` is true
#   - 'archive' is the synthetic_state for all dossiers
#     where archive is true,
#     except those whose synthetic_state is already 'termine'
#   - For all other dossiers, the synthetic_state and the state are the same
class AdministrateurUsageStatisticsService
  def update_administrateurs
    Administrateur.find_each do |administrateur|
      stats = administrateur_stats(administrateur)
      api.identify(administrateur.email, stats)
    end
    api.run
  end

  private

  def api
    @api ||= Sendinblue::Api.new_properly_configured!
  end

  def administrateur_stats(administrateur)
    nb_dossiers_by_procedure_id = nb_dossiers_by_procedure_id(administrateur.id)
    nb_dossiers_by_synthetic_state = nb_dossiers_by_synthetic_state(administrateur.id)
    nb_dossiers_roi = nb_dossiers_by_procedure_id.reject { |procedure_id, _count| is_brouillon(procedure_id) }.map { |_procedure_id, count| count }.sum

    result = {
      ds_sign_in_count: administrateur.sign_in_count,
      ds_created_at: administrateur.created_at,
      ds_active: administrateur.active,
      ds_id: administrateur.id,
      ds_features: administrateur.features.to_json,
      nb_services: nb_services_by_administrateur_id[administrateur.id],
      nb_instructeurs: nb_instructeurs_by_administrateur_id[administrateur.id],

      ds_nb_demarches_actives: nb_demarches_by_administrateur_id_and_state[[administrateur.id, "publiee"]],
      ds_nb_demarches_archives: nb_demarches_by_administrateur_id_and_state[[administrateur.id, "archivee"]],
      ds_nb_demarches_brouillons: nb_demarches_by_administrateur_id_and_state[[administrateur.id, "brouillon"]],

      nb_demarches_test: nb_dossiers_by_procedure_id
        .select { |procedure_id, count| count > 0 && is_brouillon(procedure_id) }
        .count,
      nb_demarches_prod: nb_dossiers_by_procedure_id
        .reject { |procedure_id, count| count == 0 || is_brouillon(procedure_id) }
        .count,
      nb_demarches_prod_20: nb_dossiers_by_procedure_id
        .reject { |procedure_id, count| count < 20 || is_brouillon(procedure_id) }
        .count,

      nb_dossiers: nb_dossiers_by_procedure_id
        .reject { |procedure_id, _count| is_brouillon(procedure_id) }
        .map { |_procedure_id, count| count }
        .sum,
      nb_dossiers_max: nb_dossiers_by_procedure_id
        .reject { |procedure_id, _count| is_brouillon(procedure_id) }
        .map { |_procedure_id, count| count }
        .max || 0,
      nb_dossiers_traite: nb_dossiers_by_synthetic_state['termine'],
      nb_dossiers_dossier_en_instruction: nb_dossiers_by_synthetic_state['en_instruction'],
      admin_roi_low: nb_dossiers_roi * 7,
      admin_roi_high: nb_dossiers_roi * 17
    }

    if administrateur.current_sign_in_at.present?
      result[:ds_current_sign_in_at] = administrateur.current_sign_in_at
    end

    if administrateur.last_sign_in_at.present?
      result[:ds_last_sign_in_at] = administrateur.last_sign_in_at
    end

    result
  end

  # Returns a hash { procedure_id => dossier_count }:
  # - The keys are the ids of procedures owned by administrateur_id
  # - The values are the number of dossiers for that procedure.
  #   Brouillons, and dossiers that are 'archive' but not 'termine', are not counted.
  def nb_dossiers_by_procedure_id(administrateur_id)
    with_default(
      0,
      nb_dossiers_by_administrateur_id_and_procedure_id_and_synthetic_state[administrateur_id]
        .map do |procedure_id, nb_dossiers_by_synthetic_state|
          [
            procedure_id,
            nb_dossiers_by_synthetic_state
              .reject { |synthetic_state, _count| ['brouillon', 'archive'].include?(synthetic_state) }
              .map { |_synthetic_state, count| count }
              .sum
          ]
        end
        .to_h
    )
  end

  # Returns a hash { synthetic_state => dossier_count }
  # - The keys are dossier synthetic_states (see class comment)
  # - The values are the number of dossiers in that synthetic state, for procedures owned by `administrateur_id`
  # Dossier on procedures en test are not counted
  def nb_dossiers_by_synthetic_state(administrateur_id)
    with_default(
      0,
      nb_dossiers_by_administrateur_id_and_procedure_id_and_synthetic_state[administrateur_id]
        .reject { |procedure_id, _nb_dossiers_by_synthetic_state| is_brouillon(procedure_id) }
        .flat_map { |_procedure_id, nb_dossiers_by_synthetic_state| nb_dossiers_by_synthetic_state.to_a }
        .group_by { |synthetic_state, _count| synthetic_state }
        .map { |synthetic_state, synthetic_states_and_counts| [synthetic_state, synthetic_states_and_counts.map { |_synthetic_state, count| count }.sum] }
        .to_h
    )
  end

  def nb_demarches_by_administrateur_id_and_state
    @nb_demarches_by_administrateur_id_and_state ||= with_default(0, Procedure.joins(:administrateurs).group('administrateurs.id', :aasm_state).count)
  end

  def nb_services_by_administrateur_id
    @nb_services_by_administrateur_id ||= with_default(0, Service.group(:administrateur_id).count)
  end

  def nb_instructeurs_by_administrateur_id
    @nb_instructeurs_by_administrateur_id ||= with_default(0, Administrateur.joins(:gestionnaires).group(:administrateur_id).count)
  end

  def nb_dossiers_by_administrateur_id_and_procedure_id_and_synthetic_state
    if @nb_dossiers_by_administrateur_id_and_procedure_id_and_synthetic_state.present?
      return @nb_dossiers_by_administrateur_id_and_procedure_id_and_synthetic_state
    end

    result = {}

    Dossier
      .joins(procedure: [:administrateurs])
      .group(
        'administrateurs.id',
        :procedure_id,
        <<~EOSQL
          CASE
            WHEN state IN('accepte', 'refuse', 'sans_suite') THEN 'termine'
            WHEN archived THEN 'archive'
            ELSE state
          END
        EOSQL
      )
      .count
      .each do |(administrateur_id, procedure_id, synthetic_state), count|
        result.deep_merge!(
          { administrateur_id => { procedure_id => { synthetic_state => count } } }
        )
      end

    @nb_dossiers_by_administrateur_id_and_procedure_id_and_synthetic_state =
      with_default({}, result)
  end

  def is_brouillon(procedure_id)
    procedure_states[procedure_id] == 'brouillon'
  end

  def procedure_states
    @procedure_states ||= Procedure.pluck(:id, :aasm_state).to_h
  end

  def with_default(default, hash)
    hash.default = default
    hash
  end
end
