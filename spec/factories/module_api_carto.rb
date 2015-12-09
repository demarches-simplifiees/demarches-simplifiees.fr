FactoryGirl.define do
  factory :module_api_carto do
    use_api_carto false
    quartiers_prioritaires false
    cadastre false

    trait :with_api_carto do
      use_api_carto true
    end

    trait :with_quartiers_prioritaires do
      use_api_carto true
      quartiers_prioritaires true
    end

    trait :with_cadastre do
      use_api_carto true
      cadastre true
    end

    trait :with_qp_and_cadastre do
      use_api_carto true
      quartiers_prioritaires true
      cadastre true
    end
  end
end
