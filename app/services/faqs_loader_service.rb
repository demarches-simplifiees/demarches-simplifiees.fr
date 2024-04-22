# frozen_string_literal: true

class FAQsLoaderService
  PATH = Rails.root.join('doc', 'faqs').freeze
  ORDER = ['usager', 'instructeur', 'administrateur'].freeze

  def initialize
    @faqs_by_path ||= Rails.cache.fetch("faqs_data", expires_in: 1.day) do
      load_faqs
    end
  end

  def find(path)
    file_path = @faqs_by_path.fetch(path).fetch(:file_path)

    FrontMatterParser::Parser.parse_file(file_path)
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
      parsed = FrontMatterParser::Parser.parse_file(file_path)
      front_matter = parsed.front_matter.symbolize_keys

      faq_data = front_matter.slice(:slug, :title, :category, :subcategory, :locale, :keywords).merge(file_path: file_path)

      path = front_matter.fetch(:category) + '/' + front_matter.fetch(:slug)
      faqs_by_path[path] = faq_data
    end
  end
end
