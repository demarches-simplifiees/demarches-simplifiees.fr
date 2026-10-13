# frozen_string_literal: true

class Columns::FollowersInstructeursColumn < Columns::DossierColumn
  def initialize(procedure_id:)
    super(procedure_id:, table: 'followers_instructeurs', column: 'email')
  end

  def value(dossier) = dossier.followers_instructeurs.map(&:email).join(' ')

  def sorted_ids(dossiers, order, **)
    # LEFT OUTER JOIN allows to keep dossiers without assigned instructeurs yet
    dossiers
      .includes(:followers_instructeurs)
      .joins('LEFT OUTER JOIN users instructeurs_users ON instructeurs_users.id = instructeurs.user_id')
      .order("instructeurs_users.email #{order}")
      .pluck(:id)
      .uniq
  end

  def filtered_ids_for_values(dossiers, values)
    return dossiers.ids unless values.any?(&:present?)

    dossiers
      .includes(:followers_instructeurs)
      .joins('INNER JOIN users instructeurs_users ON instructeurs_users.id = instructeurs.user_id')
      .filter_ilike('instructeurs_users', :email, values) # ilike OK, user may want to search by *@domain
      .ids
  end
end
