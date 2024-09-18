# frozen_string_literal: true

new_frequency_lists = ['words_fr', 'passwords_fr', 'surnames_fr', 'female_names_fr', 'male_names_fr'].index_with do |n|
    Zxcvbn.file_enumerator(Rails.root.join("config/zxcvbn_frequency_lists/#{n}.txt"))
  end

new_ranked_dictionary = new_frequency_lists.transform_values do |lst|
  Zxcvbn::Matching.build_ranked_dict(lst)
end

Zxcvbn::Matching::RANKED_DICTIONARIES.merge! new_ranked_dictionary
