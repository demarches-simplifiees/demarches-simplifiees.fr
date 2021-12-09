FactoryBot.define do
  factory :bulk_message do
    body { 'bonjour' }
    dossier_count { 1 }
    dossier_state { Dossier.states.fetch(:brouillon) }
    sent_at { 1.day.ago }
    instructeur { association :instructeur }
    groupe_instructeurs { [association(:groupe_instructeur, strategy: :build)] }
  end
end
