FactoryBot.define do
  factory :drop_down_list do
    value { "val1\r\nval2\r\n--separateur--\r\nval3" }

    trait :long do
      value { "alpha\r\nbravo\r\n--separateur--\r\ncharly\r\ndelta\r\necho\r\nfox-trot\r\ngolf" }
    end
  end
end
