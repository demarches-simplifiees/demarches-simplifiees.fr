class OperationAuthorSerializer < ActiveModel::Serializer
  attributes :id, :email

  def id
    case object
    when User
      "Usager##{object.id}"
    when Gestionnaire
      "Instructeur##{object.id}"
    when Administrateur
      "Administrateur##{object.id}"
    when Administration
      "Manager##{object.id}"
    else
      nil
    end
  end
end
