# == Schema Information
#
# Table name: dossier_batch_operations
#
#  id                 :bigint           not null, primary key
#  state              :string           default("pending"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  batch_operation_id :bigint           not null
#  dossier_id         :bigint           not null
#
class DossierBatchOperation < ApplicationRecord
  belongs_to :dossier
  belongs_to :batch_operation
  has_many :groupe_instructeurs, through: :dossier

  enum state: {
    pending: 'pending',
    success: 'success',
    error:   'error'
  }

  include AASM

  aasm whiny_persistence: true, column: :state, enum: true do
    state :pending, initial: true
    state :success
    state :error

    event :done do
      transitions from: :pending, to: :success
      transitions from: :error, to: :success
    end

    event :fail do
      transitions from: :pending, to: :error
    end
  end
end
