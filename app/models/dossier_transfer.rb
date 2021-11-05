# == Schema Information
#
# Table name: dossier_transfers
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class DossierTransfer < ApplicationRecord
  has_many :dossiers, dependent: :nullify

  EXPIRATION_LIMIT = 2.weeks

  scope :pending, -> { where('created_at > ?', (Time.zone.now - EXPIRATION_LIMIT)) }
  scope :stale, -> { where('created_at < ?', (Time.zone.now - EXPIRATION_LIMIT)) }
  scope :with_dossiers, -> { joins(:dossiers) }

  after_create_commit :send_notification

  def self.initiate(email, dossiers)
    create(email: email, dossiers: dossiers)
  end

  def self.accept(id, current_user)
    transfer = pending.find_by(id: id, email: current_user.email)

    if transfer && transfer.dossiers.present?
      Invite
        .where(dossier: transfer.dossiers, email: transfer.email)
        .destroy_all
      DossierTransferLog.create(transfer.dossiers.map do |dossier|
        {
          dossier: dossier,
          from: dossier.user.email,
          to: transfer.email
        }
      end)
      transfer.dossiers.update_all(user_id: current_user.id)
      transfer.destroy
    end
  end

  def user_locale
    User.find_by(email: email)&.locale || I18n.default_locale
  end

  private

  def send_notification
    DossierMailer.notify_transfer(self).deliver_later
  end
end
