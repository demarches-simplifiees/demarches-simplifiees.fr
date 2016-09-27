class DossiersListGestionnaireService
  def initialize current_devise_profil, liste, procedure = nil
    @current_devise_profil = current_devise_profil
    @liste = liste
    @procedure = procedure
  end

  def dossiers_to_display
    {'nouveaux' => nouveaux,
     'a_traiter' => waiting_for_gestionnaire,
     'en_attente' => waiting_for_user,
     'deposes' => deposes,
     'a_instruire' => a_instruire,
     'termine' => termine}[@liste]
  end

  def nouveaux
    @nouveaux ||= filter_dossiers.nouveaux
  end

  def waiting_for_gestionnaire
    @waiting_for_gestionnaire ||= filter_dossiers.waiting_for_gestionnaire
  end

  def waiting_for_user
    @waiting_for_user ||= filter_dossiers.waiting_for_user
  end

  def deposes
    @deposes ||= filter_dossiers.deposes
  end

  def a_instruire
    @a_instruire ||= filter_dossiers.a_instruire
  end

  def termine
    @termine ||= filter_dossiers.termine
  end

  def filter_dossiers
    @filter_dossiers ||= @procedure.nil? ? @current_devise_profil.dossiers : @procedure.dossiers
  end

  def filter_procedure_reset!
    filter_procedure! nil
  end

  def filter_procedure! procedure_id
    @current_devise_profil.update_column :procedure_filter, procedure_id
  end

  def default_sort
    sort_preference = @current_devise_profil.preference_list_dossiers
                          .where(procedure: @procedure)
                          .where.not(order: nil).first

    return {'nil' => 'nil'} if sort_preference.nil?

    {
        [sort_preference.table, sort_preference.attr]
            .reject(&:nil?)
            .join('.') => sort_preference.order
    }
  end

  def change_sort! new_sort

    raw_table_attr = new_sort.keys.first.split('.')
    order = new_sort.values.first

    table = (raw_table_attr.size == 2 ? raw_table_attr.first : nil)
    attr = (raw_table_attr.size == 2 ? raw_table_attr.second : raw_table_attr.first)

    reset_sort!

    @current_devise_profil.preference_list_dossiers
        .find_by(table: table, attr: attr, procedure: @procedure)
        .update order: order
  end

  def reset_sort!
    @current_devise_profil.preference_list_dossiers
        .where(procedure: @procedure)
        .where.not(order: nil)
        .update_all order: nil
  end
end