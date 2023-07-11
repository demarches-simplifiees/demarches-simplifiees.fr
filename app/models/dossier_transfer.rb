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
  include EmailSanitizableConcern
  has_many :dossiers, dependent: :nullify

  EXPIRATION_LIMIT = 2.weeks

  validates :email, format: { with: Devise.email_regexp }
  before_validation -> { sanitize_email(:email) }

  scope :pending, -> { where('created_at > ?', (Time.zone.now - EXPIRATION_LIMIT)) }
  scope :stale, -> { where('created_at < ?', (Time.zone.now - EXPIRATION_LIMIT)) }
  scope :with_dossiers, -> { joins(:dossiers).merge(Dossier.visible_by_user) }
  scope :for_email, -> (email) { includes(dossiers: :user).with_dossiers.where(email: email) }

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
      transfer.destroy_and_nullify
    end
  end

  def user_locale
    User.find_by(email: email)&.locale || I18n.default_locale
  end

  def destroy_and_nullify
    transaction do
      # Rails cascading is not working with default scopes. Doing nullify cascade manually.
      dossiers.update_all(dossier_transfer_id: nil)
      destroy
    end
  end

  def self.destroy_stale
    transaction do
      # Rails cascading is not working with default scopes. Doing nullify cascade manually.
      Dossier.where(transfer: stale).update_all(dossier_transfer_id: nil)
      stale.destroy_all
    end
  end

  private

  def send_notification
    DossierMailer.notify_transfer(self).deliver_later
  end
end
