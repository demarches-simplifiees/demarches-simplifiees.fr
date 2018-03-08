class AddLastViewsAtToFollow < ActiveRecord::Migration[5.2]
  def change
    add_column :follows, :demande_seen_at, :datetime
    add_column :follows, :annotations_privees_seen_at, :datetime
    add_column :follows, :avis_seen_at, :datetime
    add_column :follows, :messagerie_seen_at, :datetime
  end
end
