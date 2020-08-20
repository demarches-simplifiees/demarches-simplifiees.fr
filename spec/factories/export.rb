FactoryBot.define do
  factory :export do
    format { :csv }
    groupe_instructeurs { [association(:groupe_instructeur)] }
  end
end
