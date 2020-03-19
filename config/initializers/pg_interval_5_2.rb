# frozen_string_literal: true

# from https://gist.github.com/Envek/7077bfc36b17233f60ad

# PostgreSQL interval data type support from https://github.com/rails/rails/pull/16919
# Works with both Rails 5.2 and 6.0
# Place this file to config/initializers/

require "active_support/duration"

# activerecord/lib/active_record/connection_adapters/postgresql/oid/interval.rb
module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID # :nodoc:
        class Interval < Type::Value # :nodoc:
          def type
            :interval
          end

          def cast_value(value)
            case value
            when ::ActiveSupport::Duration
              value
            when ::String
              begin
                ::ActiveSupport::Duration.parse(value)
              rescue ::ActiveSupport::Duration::ISO8601Parser::ParsingError
                nil
              end
            else
              super
            end
          end

          def serialize(value)
            case value
            when ::ActiveSupport::Duration
              value.iso8601(precision: self.precision)
            when ::Numeric
              # Sometimes operations on Times returns just float number of seconds so we need to handle that.
              # Example: Time.current - (Time.current + 1.hour) # => -3600.000001776 (Float)
              value.seconds.iso8601(precision: self.precision)
            else
              super
            end
          end

          def type_cast_for_schema(value)
            serialize(value).inspect
          end
        end
      end
    end
  end
end

# activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb
require 'active_record/connection_adapters/postgresql_adapter'
PostgreSQLAdapterWithInterval = Module.new do
  def initialize_type_map(m = type_map)
    super
    m.register_type "interval" do |*_args, sql_type|
      precision = extract_precision(sql_type)
      ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Interval.new(precision: precision)
    end
  end

  def configure_connection
    super
    execute('SET intervalstyle = iso_8601', 'SCHEMA')
  end

  ActiveRecord::Type.register(:interval, ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Interval, adapter: :postgresql)
end
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterWithInterval)

# activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb
require 'active_record/connection_adapters/postgresql/schema_statements'
module SchemaStatementsWithInterval
  def type_to_sql(type, limit: nil, precision: nil, scale: nil, array: nil, **)
    case type.to_s
    when 'interval'
      case precision
      when nil;  "interval"
      when 0..6; "interval(#{precision})"
      else raise(ActiveRecordError, "No interval type has precision of #{precision}. The allowed range of precision is from 0 to 6")
      end
    else
      super
    end
  end
end
ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements.prepend(SchemaStatementsWithInterval)
