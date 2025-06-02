# frozen_string_literal: true

class AdministrateurDeletionService
  include Dry::Monads[:result]

  attr_reader :super_admin, :admin, :owned_procedures, :shared_procedures

  def initialize(super_admin, admin)
    @super_admin = super_admin
    @admin = admin
    @owned_procedures, @shared_procedures = admin
      .procedures
      .with_discarded
      .partition { _1.administrateurs.one? }
  end

  def call
    return Failure(:cannot_be_deleted) unless admin.can_be_deleted?

    result = nil

    ApplicationRecord.transaction do
      delete_admin_from_shared_procedures
      delete_procedures_without_dossier

      if admin.procedures.with_discarded.count.positive?
        result = Failure(:still_procedures)
        raise ActiveRecord::Rollback
      end

      delete_services_without_procedures
      transfer_services
      if admin.services.count.positive?
        result = Failure(:still_services)
        raise ActiveRecord::Rollback
      end

      admin.destroy!
      result = Success(:ok)
    end
    result
  end

  private

  def delete_admin_from_shared_procedures
    @shared_procedures.each { _1.administrateurs.delete(admin) }
  end

  def delete_procedures_without_dossier
    procedures_without_dossier = owned_procedures.filter { _1.dossiers.empty? }
    procedures_without_dossier.each { |p| p.discard_and_keep_track!(super_admin) unless p.discarded? }
    procedures_without_dossier.each(&:purge_discarded)
  end

  def delete_services_without_procedures
    admin.services.filter { _1.procedures.with_discarded.count.zero? }.each(&:destroy)
  end

  def transfer_services
    shared_procedures.each do |procedure|
      next if procedure.service.nil?
      next_admin = procedure.administrateurs.where.not(id: admin.id).first
      procedure.service.update(administrateur: next_admin)
    end
  end
end
