feature "As an administrator I wanna to set my API Particulier token", js: true do
  let(:administrateur) { create(:administrateur) }

  let(:procedure) do
    create(:procedure, :with_service, :with_instructeur,
      aasm_state: :publiee,
      administrateurs: [administrateur],
      libelle: "libellé de la procédure",
      path: "libelle-de-la-procedure")
  end

  before do
    login_as administrateur.user, scope: :user
  end

  context "when API Particulier is disabled" do
    before do
      Flipper.disable(:api_particulier)
      visit admin_procedure_path(procedure)
      expect(page).to have_content(procedure.libelle)
      expect(page).to have_content("Jeton Entreprise")
    end

    scenario do
      expect(page).not_to have_content("Jeton Particulier")
    end
  end

  context "when API Particulier is enabled" do
    before do
      Flipper.enable(:api_particulier)
      visit admin_procedure_path(procedure)
      expect(page).to have_content(procedure.libelle)
      expect(page).to have_content("Jeton Entreprise")
    end

    scenario do
      expect(page).to have_content("Jeton Particulier")
    end
  end
end
