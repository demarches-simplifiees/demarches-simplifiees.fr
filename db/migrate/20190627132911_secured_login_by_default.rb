class SecuredLoginByDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:gestionnaires, :features, from: {}, to: { "enable_email_login_token": true })
  end
end
