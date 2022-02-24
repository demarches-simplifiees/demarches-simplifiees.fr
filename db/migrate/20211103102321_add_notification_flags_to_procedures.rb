class AddNotificationFlagsToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :brouillon_close_to_expiration_notification_enabled_for_user, :boolean, default: true
    add_column :procedures, :en_construction_close_to_expiration_notification_enabled_for_user, :boolean, default: true
    add_column :procedures, :termine_close_to_expiration_notification_enabled_for_user, :boolean, default: true

    add_column :procedures, :en_construction_close_to_expiration_notification_enabled_for_administration, :boolean, default: true
    add_column :procedures, :termine_close_to_expiration_notification_enabled_for_administration, :boolean, default: true

    add_column :procedures, :brouillon_expired_destroy_notification_enabled_for_user, :boolean, default: true
    add_column :procedures, :en_construction_expired_destroy_notification_enabled_for_user, :boolean, default: true
    add_column :procedures, :termine_expired_destroy_notification_enabled_for_user, :boolean, default: true

    add_column :procedures, :en_construction_expired_destroy_notification_enabled_for_administration, :boolean, default: true
    add_column :procedures, :termine_expired_destroy_notification_enabled_for_administration, :boolean, default: true

    add_column :procedures, :brouillon_near_closing_date_notification_enabled_for_user, :boolean, default: true
  end
end
