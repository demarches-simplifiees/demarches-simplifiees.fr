# frozen_string_literal: true

class ProcedurePresentation < ApplicationRecord
  TYPE_DE_CHAMP = 'type_de_champ'

  belongs_to :assign_to, optional: false
  has_many :exports, dependent: :destroy

  delegate :procedure, :instructeur, to: :assign_to

  attribute :displayed_columns, :column, array: true

  attribute :sorted_column, :sorted_column
  def sorted_column = super || procedure.default_sorted_column # Dummy override to set default value

  attribute :a_suivre_filters, :filtered_column, array: true
  attribute :suivis_filters, :filtered_column, array: true
  attribute :traites_filters, :filtered_column, array: true
  attribute :tous_filters, :filtered_column, array: true
  attribute :supprimes_filters, :filtered_column, array: true
  attribute :supprimes_recemment_filters, :filtered_column, array: true
  attribute :expirant_filters, :filtered_column, array: true
  attribute :archives_filters, :filtered_column, array: true

  before_create { self.displayed_columns = procedure.default_displayed_columns }

  validates_associated :a_suivre_filters, :suivis_filters, :traites_filters,
    :tous_filters, :supprimes_filters, :expirant_filters, :archives_filters

  def filters_for(statut)
    send(filters_name_for(statut))
  end

  def filters_name_for(statut) = statut.tr('-', '_').then { "#{_1}_filters" }

  def displayed_fields_for_headers
    [
      procedure.dossier_id_column,
      *displayed_columns,
      procedure.dossier_state_column,
      *procedure.sva_svr_columns
    ]
  end

  def filtered_sorted_ids(dossiers, statut, count: nil)
    dossiers_by_statut = dossiers.by_statut(statut, instructeur)
    dossiers_sorted_ids = self.sorted_ids(dossiers_by_statut, count || dossiers_by_statut.size)

    if filters_for(statut).present?
      dossiers_sorted_ids.intersection(filtered_ids(dossiers_by_statut, statut))
    else
      dossiers_sorted_ids
    end
  end

  def human_value_for_filter(filtered_column)
    if filtered_column.column.table == TYPE_DE_CHAMP
      find_type_de_champ(filtered_column.column.column).dynamic_type.filter_to_human(filtered_column.filter)
    elsif filtered_column.column.column == 'state'
      if filtered_column.filter == 'pending_correction'
        Dossier.human_attribute_name("pending_correction.for_instructeur")
      else
        Dossier.human_attribute_name("state.#{filtered_column.filter}")
      end
    elsif filtered_column.column.table == 'groupe_instructeur' && filtered_column.column.column == 'id'
      instructeur.groupe_instructeurs
        .find { _1.id == filtered_column.filter.to_i }&.label || filtered_column.filter
    else
      column = procedure.columns.find { _1.table == filtered_column.column.table && _1.column == filtered_column.column.column }

      if column.type == :date
        parsed_date = safe_parse_date(filtered_column.filter)

        return parsed_date.present? ? I18n.l(parsed_date) : nil
      end

      filtered_column.filter
    end
  end

  def safe_parse_date(string)
    Date.parse(string)
  rescue Date::Error
    nil
  end

  def snapshot
    slice(:filters, :sort, :displayed_fields)
  end

  private

  def sorted_ids(dossiers, count)
    table = sorted_column.column.table
    column = sorted_column.column.column
    order = sorted_column.order

    case table
    when 'notifications'
      dossiers_id_with_notification = dossiers.merge(instructeur.followed_dossiers).with_notifications.ids
      if order == 'desc'
        dossiers_id_with_notification +
            (dossiers.order('dossiers.updated_at desc').ids - dossiers_id_with_notification)
      else
        (dossiers.order('dossiers.updated_at asc').ids - dossiers_id_with_notification) +
            dossiers_id_with_notification
      end
    when TYPE_DE_CHAMP
      ids = dossiers
        .with_type_de_champ(column)
        .order("champs.value #{order}")
        .pluck(:id)
      if ids.size != count
        rest = dossiers.where.not(id: ids).order(id: order).pluck(:id)
        order == 'asc' ? ids + rest : rest + ids
      else
        ids
      end
    when 'followers_instructeurs'
      assert_supported_column(table, column)
      # LEFT OUTER JOIN allows to keep dossiers without assigned instructeurs yet
      dossiers
        .includes(:followers_instructeurs)
        .joins('LEFT OUTER JOIN users instructeurs_users ON instructeurs_users.id = instructeurs.user_id')
        .order("instructeurs_users.email #{order}")
        .pluck(:id)
        .uniq
    when 'avis'
      dossiers.includes(table)
        .order("#{self.class.sanitized_column(table, column)} #{order}")
        .pluck(:id)
        .uniq
    when 'self', 'user', 'individual', 'etablissement', 'groupe_instructeur'
      (table == 'self' ? dossiers : dossiers.includes(table))
        .order("#{self.class.sanitized_column(table, column)} #{order}")
        .pluck(:id)
    end
  end

  def filtered_ids(dossiers, statut)
    filters_for(statut)
      .group_by { |filter| filter.column.then { [_1.table, _1.column] } }
      .map do |(table, column), filters_for_column|
      values = filters_for_column.map(&:filter)
      filtered_column = filters_for_column.first.column
      value_column = filtered_column.value_column

      if filtered_column.is_a?(Columns::JSONPathColumn)
        filtered_column.filtered_ids(dossiers, values)
      else
        case table
        when 'self'
          if filtered_column.type == :date
            dates = values
              .filter_map { |v| Time.zone.parse(v).beginning_of_day rescue nil }

            dossiers.filter_by_datetimes(column, dates)
          elsif filtered_column.column == "state" && values.include?("pending_correction")
            dossiers.joins(:corrections).where(corrections: DossierCorrection.pending)
          elsif filtered_column.column == "state" && values.include?("en_construction")
            dossiers.where("dossiers.#{column} IN (?)", values).includes(:corrections).where.not(corrections: DossierCorrection.pending)
          else
            dossiers.where("dossiers.#{column} IN (?)", values)
          end
        when TYPE_DE_CHAMP
          if filtered_column.type == :enum
            dossiers.with_type_de_champ(column)
              .filter_enum(:champs, value_column, values)
          else
            dossiers.with_type_de_champ(column)
              .filter_ilike(:champs, value_column, values)
          end
        when 'etablissement'
          if column == 'entreprise_date_creation'
            dates = values
              .filter_map { |v| v.to_date rescue nil }

            dossiers
              .includes(table)
              .where(table.pluralize => { column => dates })
          else
            dossiers
              .includes(table)
              .filter_ilike(table, column, values)
          end
        when 'followers_instructeurs'
          assert_supported_column(table, column)
          dossiers
            .includes(:followers_instructeurs)
            .joins('INNER JOIN users instructeurs_users ON instructeurs_users.id = instructeurs.user_id')
            .filter_ilike('instructeurs_users', :email, values) # ilike OK, user may want to search by *@domain
        when 'user', 'individual' # user_columns: [email], individual_columns: ['nom', 'prenom', 'gender']
          dossiers
            .includes(table)
            .filter_ilike(table, column, values) # ilike or where column == 'value' are both valid, we opted for ilike
        when 'groupe_instructeur'
          assert_supported_column(table, column)

          dossiers
            .joins(:groupe_instructeur)
            .where(groupe_instructeur_id: values)
        end.pluck(:id)
      end
    end.reduce(:&)
  end

  def find_type_de_champ(column)
    TypeDeChamp
      .joins(:revision_types_de_champ)
      .where(revision_types_de_champ: { revision_id: procedure.revisions })
      .order(created_at: :desc)
      .find_by(stable_id: column)
  end

  def self.sanitized_column(association, column)
    table = if association == 'self'
      Dossier.table_name
    elsif (association_reflection = Dossier.reflect_on_association(association))
      association_reflection.klass.table_name
    else
      # Allow filtering on a joined table alias (which doesn’t exist
      # in the ActiveRecord domain).
      association
    end

    [table, column]
      .map { |name| ActiveRecord::Base.connection.quote_column_name(name) }
      .join('.')
  end

  def assert_supported_column(table, column)
    if table == 'followers_instructeurs' && column != 'email'
      raise ArgumentError, 'Table `followers_instructeurs` only supports the `email` column.'
    end
    if table == 'groupe_instructeur' && (column != 'label' && column != 'id')
      raise ArgumentError, 'Table `groupe_instructeur` only supports the `label` or `id` column.'
    end
  end
end
