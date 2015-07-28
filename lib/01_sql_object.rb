require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    columns.first.map { |title| title.to_sym }

  end

  def self.finalize!
    self.columns.each do |name|
      define_method("#{name}=") do |arg|
        attributes[name] = arg
      end

      define_method("#{name}") do
        attributes[name]
      end
    end
  end

  def self.table_name=(table_name = nil)
      @table_name = table_name
  end

  def self.table_name
    if @table_name == nil
      @table_name = self.name.tableize
    else
      @table_name
    end
  end

  def self.all
    all = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    parse_all(all)
  end

  def self.parse_all(results)
    new_objects = []
    results.each do |result|
      new_object = self.new
      result.each do |x,y|
        new_object.send("#{x}=", y)
      end
      new_objects << new_object
    end
    new_objects
  end

  def self.find(id)
    all = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = #{id}
    SQL

    self.parse_all(all).first
  end

  def initialize(params = {})
    params.each do |key,value|
      symbol_name = key.to_sym
      if !self.class.columns.include?(symbol_name)
        raise "unknown attribute '#{key}'"
      else
        self.send("#{key}=", value)
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.attributes.values
  end

  def insert
    columns_array = self.class.columns
    col_names = columns_array.join(", ")

    params = self.attribute_values
    params.unshift(DBConnection.last_insert_row_id)

    q_mark_array = []
    columns_array.count.times do
        q_mark_array << "?"
    end

    q_marks = q_mark_array.join(", ")

    DBConnection.execute(<<-SQL, params)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{q_marks})
    SQL

    self.id = DBConnection.last_insert_row_id

  end

  def update
    columns_array = self.class.columns

    col_names = columns_array.join(" = ?, ") + " = ?"

    puts col_names

    params = self.attribute_values
    params.push(self.id)

    q_mark_array = []
    columns_array.count.times do
        q_mark_array << "?"
    end
    puts params
    q_marks = q_mark_array.join(", ")

    DBConnection.execute(<<-SQL, params)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL

  end

  def save
    if id.nil?
      self.insert
    else
      self.update
    end
  end
end
