class AdminTypesDeChampFacades
  include Rails.application.routes.url_helpers

  def initialize private, procedure
    @private = private
    @procedure = procedure
  end

  def private
    @private
  end

  def active
    @private ? 'Champs privés' : 'Champs'
  end

  def url
    @private ? admin_procedure_types_de_champ_private_path(@procedure) : admin_procedure_types_de_champ_path(@procedure)
  end

  def types_de_champ
    @private ? @procedure.types_de_champ_private_ordered.decorate : @procedure.types_de_champ_ordered.decorate
  end

  def new_type_de_champ
    @private ? TypeDeChampPrivate.new.decorate : TypeDeChampPublic.new.decorate
  end

  def fields_for_var
    @private ? :types_de_champ_private : :types_de_champ
  end

  def move_up_url ff
    @private ? move_up_admin_procedure_types_de_champ_private_path(@procedure, ff.index) : move_up_admin_procedure_types_de_champ_path(@procedure, ff.index)
  end

  def move_down_url ff
    @private ? move_down_admin_procedure_types_de_champ_private_path(@procedure, ff.index) : move_down_admin_procedure_types_de_champ_path(@procedure, ff.index)
  end

  def delete_url ff
    @private ? admin_procedure_type_de_champ_private_path(@procedure, ff.object.id) : admin_procedure_type_de_champ_path(@procedure, ff.object.id)
  end

  def add_button_id
    @private ? :add_type_de_champ_private : :add_type_de_champ
  end
end