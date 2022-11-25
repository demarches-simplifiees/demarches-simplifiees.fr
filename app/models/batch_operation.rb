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
  belongs_to :instructeur

  validates :operation, presence: true

  def enqueue_all
    Dossier.joins(:procedure)
      .where(procedure: { id: instructeur.procedures.ids })
      .where(id: dossiers.ids)
      .map { |dossier| BatchOperationProcessOneJob.perform_later(self, dossier) }
  end

  def track_dossier_processed(success, dossier)
    transaction do
      dossier.update(batch_operation: nil)
      reload
      manager = Arel::UpdateManager.new.table(arel_table).where(arel_table[:id].eq(id))
      values = []
      values.push([arel_table[:run_at], Time.zone.now]) if called_for_first_time?
      values.push([arel_table[:finished_at], Time.zone.now]) if called_for_last_time?
      if success
        values.push([arel_table[:success_dossier_ids],Arel::Nodes::NamedFunction.new('array_append', [arel_table[:success_dossier_ids], dossier.id])])
        values.push([arel_table[:failed_dossier_ids], Arel::Nodes::NamedFunction.new('array_remove', [arel_table[:failed_dossier_ids], dossier.id])])
      else
        values.push([arel_table[:failed_dossier_ids], Arel::Nodes::NamedFunction.new('array_append', [arel_table[:failed_dossier_ids], dossier.id])])
      end
      manager.set(values)
      ActiveRecord::Base.connection.update(manager.to_sql)
    end
  end

  def arel_table
    BatchOperation.arel_table
  end

  def process_one(dossier)
    case operation
    when BatchOperation.operations.fetch(:archiver)
      dossier.archiver!(instructeur)
    end
    true
  end

  def called_for_first_time?
    run_at.nil?
  end

  def called_for_last_time? # beware, must be reloaded first
    dossiers.count.zero?
  end

  private

  # safer enqueue, in case instructeur kept the page for some time and their is a Dossier.id which does not fit current transaction
  def dossiers_safe_scope
    query = Dossier.joins(:procedure)
      .where(procedure: { id: instructeur.procedures.ids })
      .where(id: dossiers.ids)
      .visible_by_administration
    # case operation
    # when BatchOperation.operations.fetch(:archiver) then
    #   query.not_archived
    # when BatchOperation.operations.fetch(:accepter) then
    #   query.state_en_instruction
    # end
  end
end
