# frozen_string_literal: true

class EnablePgcrypto < ActiveRecord::Migration[6.1]
  # see: https://pawelurbanek.com/uuid-order-rails -> use uuid for id
  def up
    enable_extension "pgcrypto"
  end

  def down
    disable_extension "pgcrypto"
  end
end
