class MoveInetColumnToString < ActiveRecord::Migration[5.0]
  def up
    change_column :users, :last_sign_in_ip, 'string'
    change_column :users, :current_sign_in_ip, 'string'

    change_column :gestionnaires, :last_sign_in_ip, 'string'
    change_column :gestionnaires, :current_sign_in_ip, 'string'

    change_column :administrateurs, :last_sign_in_ip, 'string'
    change_column :administrateurs, :current_sign_in_ip, 'string'

    change_column :administrations, :last_sign_in_ip, 'string'
    change_column :administrations, :current_sign_in_ip, 'string'
  end

  def down
    change_column :users, :last_sign_in_ip, 'inet USING last_sign_in_ip::inet'
    change_column :users, :current_sign_in_ip, 'inet USING last_sign_in_ip::inet'

    change_column :gestionnaires, :last_sign_in_ip, 'inet USING last_sign_in_ip::inet'
    change_column :gestionnaires, :current_sign_in_ip, 'inet USING last_sign_in_ip::inet'

    change_column :administrateurs, :last_sign_in_ip, 'inet USING last_sign_in_ip::inet'
    change_column :administrateurs, :current_sign_in_ip, 'inet USING last_sign_in_ip::inet'

    change_column :administrations, :last_sign_in_ip, 'inet USING last_sign_in_ip::inet'
    change_column :administrations, :current_sign_in_ip, 'inet USING last_sign_in_ip::inet'
  end
end
