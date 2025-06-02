# frozen_string_literal: true

describe '20240530090353_block_dubious_email' do
  let(:rake_task) { Rake::Task['after_party:block_dubious_email'] }
  let(:now) { Time.current }
  let(:confirmed_user) { create(:user, email_verified_at: now, created_at: 1.year.ago) }
  let(:unconfirmed_user) { create(:user, email_verified_at: now, created_at: 1.year.ago, confirmed_at: nil) }

  let(:never_seen_instructeur) do
    instructeur = create(:instructeur)
    instructeur.user.update!(email_verified_at: now, created_at: 1.year.ago)
    instructeur.user
  end
  let(:seen_instructeur) do
    instructeur = create(:instructeur)
    instructeur.user.update!(
      email_verified_at: now,
      created_at: 1.year.ago,
      last_sign_in_at: now
    )
    instructeur.user
  end

  let(:young_never_seen_instructeur) do
    instructeur = create(:instructeur)
    instructeur.user.update!(
      email_verified_at: now,
      created_at: 2.months.ago,
      confirmed_at: nil
    )
    instructeur.user
  end

  subject(:run_task) { rake_task.invoke }

  after { rake_task.reenable }

  it 'block_dubious_email' do
    people = [
      confirmed_user,
      unconfirmed_user,
      never_seen_instructeur,
      young_never_seen_instructeur,
      seen_instructeur
    ]

    expect(people.map(&:email_verified_at)).to all(be_present)

    run_task
    people.each(&:reload)

    expect(confirmed_user.email_verified_at).to be_present
    expect(seen_instructeur.email_verified_at).to be_present
    expect(young_never_seen_instructeur.email_verified_at).to be_present

    expect(never_seen_instructeur.email_verified_at).to be_nil
    expect(unconfirmed_user.email_verified_at).to be_nil
  end
end
