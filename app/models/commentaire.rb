class Commentaire < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :champ

  belongs_to :piece_justificative

  after_save :internal_notification

  def header
    "#{email}, " + created_at.localtime.strftime('%d %b %Y %H:%M')
  end

  private

  def internal_notification
    if email == dossier.user.email || dossier.invites_user.pluck(:email).to_a.include?(email)
      NotificationService.new('commentaire', self.dossier.id).notify
    end
  end
end
