FactoryBot.define do
  factory :export do
    format { :csv }
    groupe_instructeurs { [create(:groupe_instructeur)] }
  end
end
