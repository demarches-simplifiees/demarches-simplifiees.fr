class DossiersListGestionnaireService
  def initialize current_devise_profil, liste, procedure = nil
    @current_devise_profil = current_devise_profil
    @liste = (DossiersListGestionnaireService.dossiers_liste_libelle.include?(liste) ? liste : 'all_state')
    @procedure = procedure
  end

  def dossiers_to_display
    @dossiers_to_display ||=
        {'nouveaux' => nouveaux,
         'a_traiter' => nouveaux,
         'a_instruire' => a_instruire,
         'termine' => termine,
         'archive' => archive,
         'all_state' => all_state}[@liste]
  end

  def self.dossiers_liste_libelle
    ['nouveaux', 'suivi', 'a_traiter', 'a_instruire', 'termine', 'all_state']
  end

  def all_state
    @all_state ||= filter_dossiers.all_state.order_by_updated_at('asc')
  end

  def suivi
    @suivi ||= @current_devise_profil.followed_dossiers.merge(dossiers_to_display)
  end

  def nouveaux
    @nouveaux ||= filter_dossiers.en_construction.order_by_updated_at('asc')
  end

  def a_instruire
    @a_instruire ||= filter_dossiers.en_instruction.order_by_updated_at('asc')
  end

  def archive
    @archive ||= filter_dossiers.archived
  end

  def termine
    @termine ||= filter_dossiers.termine.order_by_updated_at('asc')
  end

  def filter_dossiers
    @filter_dossiers ||= @procedure.nil? ? @current_devise_profil.dossiers.joins(joins_filter).where(where_filter) : @procedure.dossiers.joins(joins_filter).where(where_filter)
    @filter_dossiers.distinct
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

  def default_page
    pref = current_preference_smart_listing_page
    return pref.page if pref.procedure == @procedure && pref.liste == @liste

    1
  end

  def change_page! new_page
    pref = current_preference_smart_listing_page

    if pref
      unless pref.liste == @liste && pref.procedure == @procedure
        pref.liste = @liste
        pref.procedure = @procedure

        if new_page.nil?
          pref.page = 1
          pref.save
        end
      end

      unless new_page.nil?
        pref.page = new_page
        pref.save
      end
    end
  end

  def change_sort! new_sort
    return if new_sort.blank?

    raw_table_attr = new_sort.keys.first.split('.')
    order = new_sort.values.first

    table = (raw_table_attr.size == 2 ? raw_table_attr.first : nil)
    attr = (raw_table_attr.size == 2 ? raw_table_attr.second : raw_table_attr.first)

    reset_sort!

    preference = @current_devise_profil.preference_list_dossiers
                     .find_by(table: table, attr: attr, procedure: @procedure)

    preference.update order: order unless (preference.nil?)
  end

  def reset_sort!
    @current_devise_profil.preference_list_dossiers
        .where(procedure: @procedure)
        .where.not(order: nil)
        .update_all order: nil
  end

  def joins_filter
    filter_preference_list.inject([]) do |acc, preference|
      acc.push(preference.table.to_sym) unless preference.table.blank? || preference.filter.blank?
      acc
    end
  end

  def where_filter
    filter_preference_list.inject('') do |acc, preference|
      unless preference.filter.blank?
        filter = preference.filter.tr('*', '%').gsub("'", "''")
        filter = "%" + filter + "%" unless filter.include? '%'

        value = preference.table_with_s_attr

        if preference.table_attr.include?('champs')
          value = 'champs.value'

          acc += (acc.to_s.empty? ? ''.to_s : " AND ") +
              'champs.type_de_champ_id = ' + preference.attr
        end

        acc += (acc.to_s.empty? ? ''.to_s : " AND ") +
            "CAST(" +
            value +
            " as TEXT)" +
            " LIKE " +
            "'" +
            filter +
            "'"
      end
      acc
    end
  end

  def add_filter new_filter
    raw_table_attr = new_filter.keys.first.split('.')
    filter = new_filter.values.first

    table = (raw_table_attr.size == 2 ? raw_table_attr.first : nil)
    attr = (raw_table_attr.size == 2 ? raw_table_attr.second : raw_table_attr.first)

    @current_devise_profil.preference_list_dossiers
        .find_by(table: table, attr: attr, procedure: @procedure)
        .update filter: filter.strip
  end

  private

  def filter_preference_list
    @filter_preference ||= @current_devise_profil.preference_list_dossiers
                               .where(procedure: @procedure)
                               .where.not(filter: nil)
                               .order(:id)
  end

  def current_preference_smart_listing_page
    @current_devise_profil.preference_smart_listing_page
  end
end
