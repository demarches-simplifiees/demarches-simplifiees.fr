namespace :'2018_09_20_procedure_presentation_entreprise' do
  task run: :environment do
    Class.new do
      def run
        fix_displayed_fields
        fix_sort
        fix_filters
      end

      def fix_displayed_fields
        ProcedurePresentation.where(%q`displayed_fields @> '[{"table": "entreprise"}]'`).each do |procedure_presentation|
          procedure_presentation.displayed_fields.each { |field| entreprise_to_etablissement(field) }

          procedure_presentation.save
        end
      end

      def fix_sort
        ProcedurePresentation.where(%q`sort @> '{"table": "entreprise"}'`).each do |procedure_presentation|
          entreprise_to_etablissement(procedure_presentation['sort'])

          procedure_presentation.save
        end
      end

      def fix_filters
        ProcedurePresentation.find_by_sql(
          <<~SQL
            SELECT procedure_presentations.*, array_agg(key) as keys
            FROM procedure_presentations, LATERAL jsonb_each(filters)
            WHERE value @> '[{"table": "entreprise"}]'
            GROUP BY id;
          SQL
        ).each do |procedure_presentation|
          procedure_presentation.keys.each do |key|
            procedure_presentation.filters[key].each { |filter| entreprise_to_etablissement(filter) }
          end

          procedure_presentation.save
        end
      end

      def entreprise_to_etablissement(field)
        if field['table'] == 'entreprise'
          field['table'] = 'etablissement'
          field['column'] = "entreprise_#{field['column']}"
        end
      end
    end.new.run
  end
end
