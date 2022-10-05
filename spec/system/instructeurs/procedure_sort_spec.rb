describe "procedure sort" do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, :with_type_de_champ, instructeurs: [instructeur]) }
  let!(:new_unfollow_dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }
  let!(:followed_dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }
  let!(:new_unfollow_dossier_2) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }

  before do
    instructeur.follow(followed_dossier)
    followed_dossier.champs.first.update(value: '123')

    login_as(instructeur.user, scope: :user)
    visit instructeur_procedure_path(procedure)
  end

  scenario "should be able to sort with header" do
    all(".dossiers-table tbody tr:nth-child(1) .number-col a", text: new_unfollow_dossier_2.id)
    all(".dossiers-table tbody tr:nth-child(2) .number-col a", text: followed_dossier.id)
    all(".dossiers-table tbody tr:nth-child(3) .number-col a", text: new_unfollow_dossier.id)

    find("thead .number-col a").click # reverse id filter

    all(".dossiers-table tbody tr:nth-child(1) .number-col a", text: new_unfollow_dossier.id)
    all(".dossiers-table tbody tr:nth-child(2) .number-col a", text: followed_dossier.id)
    all(".dossiers-table tbody tr:nth-child(3) .number-col a", text: new_unfollow_dossier_2.id)
  end

  scenario "should be able to sort with direct link to notificaiton filter" do
    # dossier sorted by id
    check "Remonter les dossiers avec une notification"

    # sort by notification
    all(".dossiers-table tbody tr:nth-child(1) .number-col a", text: followed_dossier.id)
    all(".dossiers-table tbody tr:nth-child(2) .number-col a", text: new_unfollow_dossier.id)
    all(".dossiers-table tbody tr:nth-child(3) .number-col a", text: new_unfollow_dossier_2.id)

    uncheck "Remonter les dossiers avec une notification"

    all(".dossiers-table tbody tr:nth-child(1) .number-col a", text: new_unfollow_dossier_2.id)
    all(".dossiers-table tbody tr:nth-child(2) .number-col a", text: followed_dossier.id)
    all(".dossiers-table tbody tr:nth-child(3) .number-col a", text: new_unfollow_dossier.id)
  end
end
