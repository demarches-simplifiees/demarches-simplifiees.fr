module Capybara
  class Session
    # Find the description of a procedure on the page
    # Usage: expect(page).to have_procedure_description(procedure)
    def has_procedure_description?(procedure)
      has_content?(procedure.libelle) && has_content?(procedure.description) && has_content?(procedure.service.email)
    end
  end
end
