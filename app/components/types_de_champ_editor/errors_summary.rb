class TypesDeChampEditor::ErrorsSummary < ApplicationComponent
  def initialize(revision:)
    @revision = revision
  end

  private

  def error_message
    @revision.errors
      .map { |error| error.options[:type_de_champ] }
      .map { |tdc| tag.li(tdc_anchor(tdc)) }
      .then { |lis| tag.ul(lis.reduce(&:+)) }
  end

  def tdc_anchor(tdc)
    tag.a(tdc.libelle, href: '#' + dom_id(tdc, :conditions), data: { turbo: false })
  end
end
