require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    keys = params.keys
    values = params.values
    where_line = keys.join(" = ? AND ") + " = ?"
    params = values
    puts where_line
    puts params
    results = DBConnection.execute(<<-SQL, params)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    self.parse_all(results)

  end
end

class SQLObject
  extend Searchable
end
