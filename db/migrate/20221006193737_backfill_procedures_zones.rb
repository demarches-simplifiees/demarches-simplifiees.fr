class BackfillProceduresZones < ActiveRecord::Migration[6.1]
  def up
    # rubocop:disable DS/Unscoped
    Procedure.unscoped.each do |procedure|
      procedure.zones << procedure.zone if procedure.zone
    end
    # rubocop:enable DS/Unscoped
  end

  def down
    # rubocop:disable DS/Unscoped
    Procedure.unscoped.each do |procedure|
      procedure.zones.destroy_all
    end
    # rubocop:enable DS/Unscoped
  end
end
