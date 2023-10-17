describe "procedure sort", js: true do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, :with_type_de_champ, instructeurs: [instructeur]) }
  let!(:new_unfollow_dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }
  let!(:followed_dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }
  let!(:followed_dossier_2) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }

  before do
    instructeur.follow(followed_dossier)
    instructeur.follow(followed_dossier_2)
    followed_dossier.champs_public.first.update(value: '123') # touch the dossier

    login_as(instructeur.user, scope: :user)
    visit instructeur_procedure_path(procedure, statut: "suivis")
  end

  scenario "should be able to sort with header" do
    # sorted by notifications (updated_at desc) by default, filtered by followed
    expect(all(".dossiers-table tbody tr").count).to eq(3)
    expect(find(".dossiers-table tbody tr:nth-child(2) .number-col a").text).to eq(followed_dossier.id.to_s)
    expect(find(".dossiers-table tbody tr:nth-child(3) .number-col a").text).to eq(followed_dossier_2.id.to_s)

    find("thead .number-col a").click # sort by id asc

    expect(find(".dossiers-table tbody tr:nth-child(2) .number-col a").text).to eq(followed_dossier.id.to_s)
    expect(find(".dossiers-table tbody tr:nth-child(3) .number-col a").text).to eq(followed_dossier_2.id.to_s)

    find("thead .number-col a").click # reverse order - sort by id desc

    expect(find(".dossiers-table tbody tr:nth-child(2) .number-col a").text).to eq(followed_dossier_2.id.to_s)
    expect(find(".dossiers-table tbody tr:nth-child(3) .number-col a").text).to eq(followed_dossier.id.to_s)
  end

  scenario "should be able to sort with header with sva date" do
    procedure.update!(sva_svr: SVASVRConfiguration.new(decision: :sva).attributes)
    followed_dossier_2.update!(sva_svr_decision_on: Time.zone.tomorrow)
    followed_dossier.update!(sva_svr_decision_on: Time.zone.today)

    visit instructeur_procedure_path(procedure, statut: "suivis")
    # sorted by notifications (updated_at desc) by default, filtered by followed
    expect(all(".dossiers-table tbody tr").count).to eq(3)
    expect(find(".dossiers-table tbody tr:nth-child(2) .number-col a").text).to eq(followed_dossier.id.to_s)
    expect(find(".dossiers-table tbody tr:nth-child(3) .number-col a").text).to eq(followed_dossier_2.id.to_s)

    find("thead .sva-col a").click # sort by sva date asc

    expect(find(".dossiers-table tbody tr:nth-child(2) .number-col a").text).to eq(followed_dossier.id.to_s)
    expect(find(".dossiers-table tbody tr:nth-child(3) .number-col a").text).to eq(followed_dossier_2.id.to_s)

    find("thead .sva-col a").click # reverse order - sort by sva date desc

    expect(find(".dossiers-table tbody tr:nth-child(2) .number-col a").text).to eq(followed_dossier_2.id.to_s)
    expect(find(".dossiers-table tbody tr:nth-child(3) .number-col a").text).to eq(followed_dossier.id.to_s)
  end

  scenario "should be able to sort with direct link to notification sort" do
    # the real input checkbox is hidden - DSFR set a fake checkbox with a label, so we can't use "check/uncheck" methods
    # but we can assert on the hidden checkbox state
    expect(page).to have_checked_field("Remonter les dossiers avec une notification")

    find("label", text: "Remonter les dossiers avec une notification").click # reverse order - sort by updated_at asc

    expect(page).not_to have_checked_field("Remonter les dossiers avec une notification")
    expect(find(".dossiers-table tbody tr:nth-child(2) .number-col a").text).to eq(followed_dossier_2.id.to_s)
    expect(find(".dossiers-table tbody tr:nth-child(3) .number-col a").text).to eq(followed_dossier.id.to_s)

    find("label", text: "Remonter les dossiers avec une notification").click # set order back - sort by updated_at desc

    expect(page).to have_checked_field("Remonter les dossiers avec une notification")
    expect(find(".dossiers-table tbody tr:nth-child(2) .number-col a").text).to eq(followed_dossier.id.to_s)
    expect(find(".dossiers-table tbody tr:nth-child(3) .number-col a").text).to eq(followed_dossier_2.id.to_s)
  end

  scenario "should be able to sort back by notification filter after any other sort" do
    find("thead .number-col a").click # sort by id asc

    expect(page).not_to have_checked_field("Remonter les dossiers avec une notification")

    find("label", text: "Remonter les dossiers avec une notification").click # sort by updated_at desc
    expect(page).to have_checked_field("Remonter les dossiers avec une notification")

    expect(find(".dossiers-table tbody tr:nth-child(2) .number-col a").text).to eq(followed_dossier.id.to_s)
    expect(find(".dossiers-table tbody tr:nth-child(3) .number-col a").text).to eq(followed_dossier_2.id.to_s)
  end
end
