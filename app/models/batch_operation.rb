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
end
