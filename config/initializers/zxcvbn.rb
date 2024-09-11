# frozen_string_literal: true

path = Rails.root.join("config/words_fr_frequency_list.txt")
lines = path.readlines.map(&:strip)
filename = File.basename(path, ".*")

new_ranked_dictionary = Hash[filename, Zxcvbn::Matching.build_ranked_dict(lines)]
# Zxcvbn::Matching::RANKED_DICTIONARIES.merge! new_ranked_dictionary
Zxcvbn::Matching::RANKED_DICTIONARIES = new_ranked_dictionary
