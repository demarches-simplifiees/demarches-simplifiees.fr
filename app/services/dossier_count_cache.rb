# frozen_string_literal: true

class DossierCountCache
  DEFAULT_TTL = 5 * 60 # seconds

  attr_reader :procedure_ids, :instructeur

  def initialize(procedure_ids:, instructeur:, ttl: DEFAULT_TTL)
    @procedure_ids = Array(procedure_ids).map(&:to_i)
    @instructeur = instructeur
    @ttl = ttl
    @group_ids_by_procedure = {}
    instructeur.groupe_instructeurs.where(procedure_id: @procedure_ids).pluck(:procedure_id, :id).each do |pid, gid|
      @group_ids_by_procedure[pid] ||= []
      @group_ids_by_procedure[pid] << gid
    end
    @group_ids_by_procedure.each { |_k, v| v.sort! }
  end

  def count_by_procedure
    fetch_raw_counts_for_procedures(procedure_ids)
  end

  private

  def fetch_raw_counts_for_procedures(procedure_ids)
    return {} if procedure_ids.empty?

    procedure_ids_by_cache_key = procedure_ids.index_by { |pid| cache_key_for(pid) }
    cache = Rails.cache.read_multi(*procedure_ids_by_cache_key.keys)

    if procedure_ids.size != cache.keys.size
      Rails.logger.info("[DossierCountCache] cache miss")
      temp = {}

      %w[tous a-suivre traites expirant].each do |statut|
        raw = instructeur
          .dossiers
          .joins(groupe_instructeur: :procedure)
          .where(procedures: { hidden_at: nil })
          .by_statut(statut)
          .group('groupe_instructeurs.procedure_id')
          .reorder(nil)
          .count
        # binding.irb
        raw.each do |(procedure_id), cnt|
          temp[procedure_id] ||= {}
          temp[procedure_id][statut] = cnt
        end
        procedure_ids.each do |pid|
          temp[pid] ||= {}
          temp[pid][statut] ||= 0
        end
      end

      # write only changed or missing payloads
      temp.each do |pid, payload|
        if !cache.key?(cache_key_for(pid))
          Rails.cache.write(cache_key_for(pid), payload, expires_in: @ttl)
        end
        cache[cache_key_for(pid)] = payload
      end
    else
      Rails.logger.info("[DossierCountCache] cache hit for procedures #{procedure_ids - cache.keys.map { |k| procedure_ids_by_cache_key[k] }}")
    end
    cache.transform_keys do |cache_key|
      procedure_ids_by_cache_key[cache_key]
    end
  end

  def cache_key_for(procedure_id)
    group_ids = @group_ids_by_procedure[procedure_id]
    group_str = group_ids.any? ? group_ids.join(',') : 'none'
    "dossier_counts:procedure:#{procedure_id}:groups:#{group_str}"
  end
end
