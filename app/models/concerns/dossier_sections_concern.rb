# frozen_string_literal: true

module DossierSectionsConcern
  extend ActiveSupport::Concern

  included do
    def sections_for(type_de_champ)
      @sections = Hash.new do |hash, parent|
        case parent
        when :public
          hash[parent] = revision.types_de_champ_public.filter(&:header_section?)
        when :private
          hash[parent] = revision.types_de_champ_private.filter(&:header_section?)
        else
          hash[parent] = revision.children_of(parent).filter(&:header_section?)
        end
      end
      @sections[revision.parent_of(type_de_champ) || (type_de_champ.public? ? :public : :private)]
    end

    def auto_numbering_section_headers_for?(type_de_champ)
      return false if revision.child?(type_de_champ)

      sections_for(type_de_champ)&.none? { _1.libelle =~ /^\d/ }
    end

    def index_for_section_header(type_de_champ)
      types_de_champ = type_de_champ.private? ? revision.types_de_champ_private : revision.types_de_champ_public
      index = 1
      types_de_champ.each do |tdc|
        if tdc.repetition?
          index_in_repetition = revision.children_of(tdc).find_index { _1.stable_id == type_de_champ.stable_id }
          return "#{index}.#{index_in_repetition + 1}" if index_in_repetition
        else
          return index if tdc.stable_id == type_de_champ.stable_id
          next unless project_champ(tdc, nil).visible?

          index += 1 if tdc.header_section?
        end
      end
      index
    end
  end
end
