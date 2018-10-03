FactoryBot.define do
  factory :procedure_presentation do
    assign_to { create(:assign_to, procedure: create(:procedure, :with_type_de_champ)) }
    sort { { "table" => "user", "column" => "email", "order" => "asc" } }
  end
end
