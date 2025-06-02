# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token

  def liveness
    render json: { status: 'ok' }, status: 200
  end

  def startup
    checks = {
      database: test_database,
      sidekiq_redis: test_sidekiq_redis,
      cache_redis: test_cache_redis,
      active_storage: test_active_storage
    }

    critical_checks = [:database, :sidekiq_redis, :cache_redis]
    critical_passed = critical_checks.all? { |check| checks[check] }

    if critical_passed
      status_code = checks.values.all? ? 200 : 206 # 206 si S3 KO mais critiques OK
      render json: {
        status: 'ready',
        checks: checks,
        critical: critical_checks.index_with { |c| checks[c] }
      }, status: status_code
    else
      render json: {
        status: 'not_ready',
        checks: checks,
        critical: critical_checks.index_with { |c| checks[c] }
      }, status: 503
    end
  end

  private

  def test_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue => e
    Rails.logger.error "Health check - Database failed: #{e.message}"
    false
  end

  def test_sidekiq_redis
    Sidekiq.redis(&:ping) == 'PONG'
  rescue => e
    Rails.logger.error "Health check - Sidekiq Redis failed: #{e.message}"
    false
  end

  def test_cache_redis
    Rails.cache.redis.ping == 'PONG'
  rescue => e
    Rails.logger.error "Health check - Cache Redis failed: #{e.message}"
    false
  end

  def test_active_storage
    # Test léger : vérifier la configuration du service
    ActiveStorage::Blob.service.respond_to?(:exist?)
    true
  rescue => e
    Rails.logger.error "Health check - ActiveStorage failed: #{e.message}"
    false
  end
end
