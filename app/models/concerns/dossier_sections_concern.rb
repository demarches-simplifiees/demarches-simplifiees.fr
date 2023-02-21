module DossierSectionsConcern
  extend ActiveSupport::Concern

  included do
    def sections_for(champ)
      @sections = Hash.new do |hash, parent|
        case parent
        when :public
          hash[parent] = champs_public.filter(&:header_section?)
        when :private
          hash[parent] = champs_private.filter(&:header_section?)
        else
          hash[parent] = parent.champs.filter(&:header_section?)
        end
      end
      @sections[champ.parent || (champ.public? ? :public : :private)]
    end

    def auto_numbering_section_headers_for?(champ)
      sections_for(champ)&.none?(&:libelle_with_section_index?)
    end

    def index_for_section_header(champ)
      champs = champ.private? ? champs_private : champs_public

      index = 1
      champs.each do |c|
        return index if c.stable_id == champ.stable_id
        next unless c.visible?

        index += 1 if c.type_de_champ.header_section?
      end
    end
  end
end
