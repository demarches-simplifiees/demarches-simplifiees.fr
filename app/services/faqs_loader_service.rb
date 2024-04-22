# frozen_string_literal: true

class FAQsLoaderService
  PATH = Rails.root.join('doc', 'faqs').freeze
  ORDER = ['usager', 'instructeur', 'administrateur'].freeze

  attr_reader :substitutions

  def initialize(substitutions)
    @substitutions = substitutions

    @faqs_by_path ||= Rails.cache.fetch(["faqs_data", ApplicationVersion.current, substitutions], expires_in: 1.week) do
      load_faqs
    end
  end

  def find(path)
    Rails.cache.fetch(["faq", path, ApplicationVersion.current, substitutions], expires_in: 1.week) do
      file_path = @faqs_by_path.fetch(path).fetch(:file_path)

      parse_with_substitutions(file_path)
    end
  end

  def faqs_for_category(category)
    @faqs_by_path.values
      .filter { |faq| faq[:category] == category }
      .group_by { |faq| faq[:subcategory] }
   end

  def all
    @faqs_by_path.values
      .group_by { |faq| faq.fetch(:category) }
      .sort_by { |category, _| ORDER.index(category) || ORDER.size }
      .to_h
      .transform_values do |faqs|
        faqs.group_by { |faq| faq.fetch(:subcategory) }
      end
  end

  private

  def load_faqs
    Dir.glob("#{PATH}/**/*.md").each_with_object({}) do |file_path, faqs_by_path|
      parsed = parse_with_substitutions(file_path)
      front_matter = parsed.front_matter.symbolize_keys

      faq_data = front_matter.slice(:slug, :title, :category, :subcategory, :locale, :keywords).merge(file_path: file_path)

      path = front_matter.fetch(:category) + '/' + front_matter.fetch(:slug)
      faqs_by_path[path] = faq_data
    end
  end

  # Substitute all string before front matter parser so metadata are also substituted.
  # using standard ruby formatting, ie => `%{my_var} % { my_var: 'value' }`
  # We have to escape % chars not used for substitutions, ie. not preceeded by {
  def parse_with_substitutions(file_path)
    substituted_content = File.read(file_path).gsub(/%(?!{)/, '%%') % substitutions

    FrontMatterParser::Parser.new(:md).call(substituted_content)
  end
end
