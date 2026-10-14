# frozen_string_literal: true

module Events
  # The routing at the deposit and every later reassignment; the routings of
  # a brouillon are not recorded. data: groupe_instructeur_id, mode
  # (DossierAssignment.modes)
  class DossierRoute < DossierEvent
  end
end
