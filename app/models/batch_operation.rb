# == Schema Information
#
# Table name: batch_operations
#
#  id                  :bigint           not null, primary key
#  failed_dossier_ids  :bigint           default([]), not null, is an Array
#  finished_at         :datetime
#  operation           :string           not null
#  payload             :jsonb            not null
#  run_at              :datetime
#  seen_at             :datetime
#  success_dossier_ids :bigint           default([]), not null, is an Array
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  instructeur_id      :bigint           not null
#

class BatchOperation < ApplicationRecord
  enum operation: {
    archiver: 'archiver'
  }

  has_many :dossiers, dependent: :nullify
  has_and_belongs_to_many :groupe_instructeurs
  belongs_to :instructeur

  validates :operation, presence: true

  RETENTION_DURATION = 4.hours
  MAX_DUREE_GENERATION = 24.hours

  scope :stale, lambda {
    where.not(finished_at: nil)
      .where('updated_at < ?', (Time.zone.now - RETENTION_DURATION))
  }

  scope :stuck, lambda {
    where(finished_at: nil)
      .where('updated_at < ?', (Time.zone.now - MAX_DUREE_GENERATION))
  }

  def dossiers_safe_scope(dossier_ids = self.dossier_ids)
    query = Dossier.joins(:procedure)
      .where(procedure: { id: instructeur.procedures.ids })
      .where(id: dossier_ids)
      .visible_by_administration
    case operation
    when BatchOperation.operations.fetch(:archiver) then
      query.not_archived.state_termine
    end
  end

  def enqueue_all
    dossiers_safe_scope # later in batch .
      .map { |dossier| BatchOperationProcessOneJob.perform_later(self, dossier) }
  end

  def process_one(dossier)
    case operation
    when BatchOperation.operations.fetch(:archiver)
      dossier.archiver!(instructeur)
    end
  end

  # use Arel::UpdateManager for array_append/array_remove (inspired by atomic_append)
  #   see: https://www.rubydoc.info/gems/arel/Arel/UpdateManager
  #   we use this approach to ensure atomicity
  def track_processed_dossier(success, dossier)
    transaction do
      dossier.update(batch_operation: nil)
      reload
      manager = Arel::UpdateManager.new.table(arel_table).where(arel_table[:id].eq(id))
      values = []
      values.push([arel_table[:run_at], Time.zone.now]) if called_for_first_time?
      values.push([arel_table[:finished_at], Time.zone.now]) if called_for_last_time?
      values.push([arel_table[:updated_at], Time.zone.now])
      if success
        values.push([arel_table[:success_dossier_ids], Arel::Nodes::NamedFunction.new('array_append', [arel_table[:success_dossier_ids], dossier.id])])
        values.push([arel_table[:failed_dossier_ids], Arel::Nodes::NamedFunction.new('array_remove', [arel_table[:failed_dossier_ids], dossier.id])])
      else
        values.push([arel_table[:failed_dossier_ids], Arel::Nodes::NamedFunction.new('array_append', [arel_table[:failed_dossier_ids], dossier.id])])
      end
      manager.set(values)
      ActiveRecord::Base.connection.update(manager.to_sql)
    end
  end

  # when an instructeur want to create a batch from his interface,
  #   another one might have run something on one of the dossier
  #   we use this approach to create a batch with given dossiers safely
  def self.safe_create!(params)
    transaction do
      instance = new(params)
      instance.dossiers = instance.dossiers_safe_scope(params[:dossier_ids])
        .not_having_batch_operation
      instance.save!
      BatchOperationEnqueueAllJob.perform_later(instance)
      instance
    end
  end

  def called_for_first_time?
    run_at.nil?
  end

  # beware, must be reloaded first
  def called_for_last_time?
    dossiers.count.zero?
  end

  def finished_and_success?
    called_for_last_time? && failed_dossier_ids.empty?
  end

  def finished_and_fails?
    called_for_last_time? && failed_dossier_ids.present?
  end

  def in_progress?
    !called_for_last_time? && (failed_dossier_ids + success_dossier_ids).present?
  end

  def beginning?
    !called_for_last_time? && (failed_dossier_ids + success_dossier_ids).empty?
  end

  private

  def arel_table
    BatchOperation.arel_table
  end
end
