module GraphqlOperationLogConcern
  extend ActiveSupport::Concern

  # This method parses GraphQL query and creates a short description of the query. It is useful for logging.
  def operation_log(query, operation_name, variables)
    return "NoQuery" if query.nil?

    operation = parse_graphql_query(query, operation_name)

    return "InvalidQuery" if operation.nil?
    return "IntrospectionQuery" if operation.name == "IntrospectionQuery"

    message = "#{operation.operation_type}: "
    message += if operation.name.present?
      "#{operation.name} { "
    else
      "{ "
    end
    message += operation.selections.map(&:name).join(', ')
    message += " } "
    message += if variables.present?
      variables.flat_map do |(name, value)|
        format_graphql_variable(name, value)
      end
    else
      operation.selections.flat_map(&:arguments).flat_map do |argument|
        format_graphql_variable(argument.name, argument.value)
      end
    end.join(', ')

    message.strip
  end

  private

  def parse_graphql_query(query, operation_name)
    operations = GraphQL.parse(query).children.filter do |node|
      node.is_a?(GraphQL::Language::Nodes::OperationDefinition)
    end
    if operations.size == 1
      operations.first
    else
      operations.find { |node| node.name == operation_name }
    end
  rescue
    nil
  end

  def format_graphql_variable(name, value)
    if value.is_a?(Hash)
      value.map do |(name, value)|
        format_graphql_variable(name, value)
      end
    elsif value.is_a?(GraphQL::Language::Nodes::InputObject)
      value.arguments.map do |argument|
        format_graphql_variable(argument.name, argument.value)
      end
    else
      "#{name}: \"#{value.to_s.truncate(10)}\""
    end
  end
end
