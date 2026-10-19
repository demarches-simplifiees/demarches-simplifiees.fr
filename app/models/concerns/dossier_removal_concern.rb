# frozen_string_literal: true

# Where a brouillon stands on its way to removal (#13915):
#
#   retained  kept, nothing announced yet; removal_due_at is the date of the
#             notice, a notice period before its expiration
#   warned    notified of its expiration; removal_due_at is the destruction
#             date, a notice period after the notice
#   hidden    trashed; removal_due_at is the purge date, two weeks after the
#             first hiding. A warned brouillon put in the trash is hidden.
#
# The expiration cron destroys a brouillon rather than trashing it, but a
# hiding by expiration still counts, as it does for the legacy purge.
#
# Every brouillon has a stage; a NULL stage means the legacy columns still
# rule the dossier, in the other states. The stage follows the notice, the
# hiding dates and expired_at in the statement writing them: through the
# before_save for creation, trash, restore, conservation extension and
# procedure reset; in SQL for the writes skipping the callbacks, the notice
# cron (warn_removal!), the autosave and every recomputing of expired_at
# (update_expiration_columns).
module DossierRemovalConcern
  extend ActiveSupport::Concern

  # A row is warned only while it is a brouillon out of the trash.
  WARNABLE = "state = 'brouillon' AND hidden_by_user_at IS NULL AND hidden_by_expired_at IS NULL"

  # Cancelling the notice takes a warned row back to retained, and leaves a
  # trashed one alone.
  UNWARN_ASSIGNMENT = "removal_stage = CASE WHEN removal_stage = 'warned' THEN 'retained' ELSE removal_stage END"

  # A new expired_at moves the notice of a retained row, and of a warned one
  # whose notice is cancelled in the same statement: both read the row
  # before the update.
  RETAINED_DUE_ASSIGNMENT = "removal_due_at = CASE WHEN removal_stage IN (:stages) THEN :notice_at ELSE removal_due_at END"

  # The notice cron's write over the current relation: the notice date on
  # every row, and the warned stage, due a notice period later, only on the
  # rows still brouillon and out of the trash, since they were loaded before.
  WARN_ASSIGNMENTS = <<~SQL.squish
    brouillon_close_to_expiration_notice_sent_at = :noticed_at,
    removal_stage = CASE WHEN #{WARNABLE} THEN 'warned' ELSE removal_stage END,
    removal_due_at = CASE WHEN #{WARNABLE} THEN :due_at ELSE removal_due_at END
  SQL

  included do
    enum :removal_stage, { retained: 'retained', warned: 'warned', hidden: 'hidden' }, prefix: :removal

    before_save :follow_removal, if: -> {
      new_record? ||
        will_save_change_to_state? ||
        will_save_change_to_hidden_by_user_at? ||
        will_save_change_to_hidden_by_expired_at? ||
        will_save_change_to_brouillon_close_to_expiration_notice_sent_at?
    }
  end

  class_methods do
    def warn_removal!(noticed_at)
      update_all([WARN_ASSIGNMENTS, { noticed_at:, due_at: noticed_at + Expired::REMAINING_WEEKS_BEFORE_EXPIRATION.weeks }])
    end
  end

  # A brouillon hidden twice keeps its first purge date.
  def trash_purge_at
    return unless brouillon?

    [hidden_by_user_at, hidden_by_expired_at].compact.min&.+(Dossier::REMAINING_WEEKS_BEFORE_DELETION.weeks)
  end

  def notice_deletion_at
    return unless brouillon?

    brouillon_close_to_expiration_notice_sent_at&.+(Expired::REMAINING_WEEKS_BEFORE_EXPIRATION.weeks)
  end

  def removal_notice_at(expired_at = self.expired_at)
    return unless brouillon?

    expired_at&.-(Expired::REMAINING_WEEKS_BEFORE_EXPIRATION.weeks)
  end

  # update_columns of expired_at or the notice, which keeps the stage in the
  # same statement: read in SQL, so that a stage written since the dossier was
  # loaded is seen, and a trashed brouillon stays hidden. Cancelling the
  # notice takes a warned brouillon back to retained; a new expired_at moves
  # the notice of a retained one.
  def update_expiration_columns(attributes)
    unwarn = attributes.key?(:brouillon_close_to_expiration_notice_sent_at)
    notice_at = removal_notice_at(attributes[:expired_at]) if attributes.key?(:expired_at)
    assignments = [self.class.sanitize_sql_for_assignment(attributes)]
    assignments << UNWARN_ASSIGNMENT if unwarn

    if attributes.key?(:expired_at)
      stages = unwarn ? ['retained', 'warned'] : ['retained']
      assignments << self.class.sanitize_sql_for_assignment([RETAINED_DUE_ASSIGNMENT, { stages:, notice_at: }])
    end

    self.class.where(id:).update_all(assignments.join(', '))

    attributes = attributes.merge(removal_stage: 'retained') if unwarn && removal_warned?
    attributes = attributes.merge(removal_due_at: notice_at) if notice_at && (attributes[:removal_stage] || removal_stage) == 'retained'
    assign_attributes(attributes)
    clear_attribute_changes(attributes.keys)
  end

  private

  def follow_removal
    if (purge_at = trash_purge_at)
      self.removal_stage, self.removal_due_at = :hidden, purge_at
    elsif (deletion_at = notice_deletion_at)
      self.removal_stage, self.removal_due_at = :warned, deletion_at
    elsif brouillon?
      self.removal_stage, self.removal_due_at = :retained, removal_notice_at
    else
      self.removal_stage, self.removal_due_at = nil, nil
    end
  end
end
