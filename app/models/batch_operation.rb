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

  def process
    case operation
    when BatchOperation.operations.fetch(:archiver)
      dossiers.map { |dossier| dossier.archiver!(instructeur) }
    end
  end
end
