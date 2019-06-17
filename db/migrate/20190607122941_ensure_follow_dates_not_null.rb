class EnsureFollowDatesNotNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :follows, :demande_seen_at, false
    change_column_null :follows, :annotations_privees_seen_at, false
    change_column_null :follows, :avis_seen_at, false
    change_column_null :follows, :messagerie_seen_at, false
  end
end
