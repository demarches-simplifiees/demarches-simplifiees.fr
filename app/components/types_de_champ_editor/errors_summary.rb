class TypesDeChampEditor::ErrorsSummary < ApplicationComponent
  def initialize(revision:)
    @revision = revision
  end

  def invalid?
    @revision.invalid?
  end

  def condition_errors?
    @revision.errors.include?(:condition)
  end

  def header_section_errors?
    @revision.errors.include?(:header_section)
  end

  def expression_reguliere_errors?
    @revision.errors.include?(:expression_reguliere)
  end

  private

  def errors_for(key)
    @revision.errors.filter { _1.attribute == key }
  end

  def error_message_for(key)
    errors_for(key)
      .map { |error| error.options[:type_de_champ] }
      .map { |tdc| tag.li(tdc_anchor(tdc, key)) }
      .then { |lis| tag.ul(lis.reduce(&:+)) }
  end

  def tdc_anchor(tdc, key)
    tag.a(tdc.libelle, href: champs_admin_procedure_path(@revision.procedure_id, anchor: dom_id(tdc.stable_self, key)), data: { turbo: false })
  end
end
