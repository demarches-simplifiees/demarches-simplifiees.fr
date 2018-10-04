namespace :'2018_10_03_remove_fc_from_procedure_presentation' do
  task run: :environment do
    Class.new do
      def run
        fix_displayed_fields
        fix_sort
        fix_filters
      end

      def fix_displayed_fields
        ProcedurePresentation.where(%q`displayed_fields @> '[{"table": "france_connect_information"}]'`).each do |procedure_presentation|
          procedure_presentation.displayed_fields = procedure_presentation.displayed_fields.reject do |df|
            df['table'] == 'france_connect_information'
          end

          procedure_presentation.save(validate: false)
        end
      end

      def fix_sort
        ProcedurePresentation.where(%q`sort @> '{"table": "france_connect_information"}'`).each do |procedure_presentation|
          procedure_presentation.sort = {
            "order" => "desc",
            "table" => "notifications",
            "column" => "notifications"
          }

          procedure_presentation.save(validate: false)
        end
      end

      def fix_filters
        ProcedurePresentation.find_by_sql(
          <<~SQL
            SELECT procedure_presentations.*
            FROM procedure_presentations, LATERAL jsonb_each(filters)
            WHERE value @> '[{"table": "france_connect_information"}]'
            GROUP BY id;
          SQL
        ).each do |procedure_presentation|
          procedure_presentation.filters.keys.each do |key|
            procedure_presentation.filters[key] = procedure_presentation.filters[key].reject do |filter|
              filter['table'] == 'france_connect_information'
            end
          end

          procedure_presentation.save
        end
      end
    end.new.run
  end
end
