# frozen_string_literal: true

class RemoveDeviseColumns < ActiveRecord::Migration[5.2]
  def change
    remove_columns :administrateurs,
      :encrypted_password,
      :reset_password_token,
      :reset_password_sent_at,
      :remember_created_at,
      :sign_in_count,
      :current_sign_in_at,
      :last_sign_in_at,
      :current_sign_in_ip,
      :last_sign_in_ip,
      :failed_attempts,
      :unlock_token,
      :locked_at

    remove_columns :instructeurs,
      :encrypted_password,
      :reset_password_token,
      :reset_password_sent_at,
      :remember_created_at,
      :sign_in_count,
      :current_sign_in_at,
      :last_sign_in_at,
      :current_sign_in_ip,
      :last_sign_in_ip,
      :failed_attempts,
      :unlock_token,
      :locked_at
  end
end
