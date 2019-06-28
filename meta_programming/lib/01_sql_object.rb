require 'byebug'
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
  return @columns unless @columns.nil?
  titles = DBConnection.execute2(<<-SQL)
  SELECT
    *
  FROM
    #{self.table_name}
  SQL
  @columns = titles[0].map{ |title| title.to_sym }
  end

  def self.finalize!
    self.columns.each do |column|  
      define_method("#{column}") { self.attributes[column.to_sym] }
      
      define_method("#{column}=") do |arg|
        self.attributes[column.to_sym] = arg
      end
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ... 

    self.to_s.split('').map{|c| c.upcase == c ? "_#{c.downcase}" : c }.join[1..-1] + 's'
  end

  def self.all
    # ...
    data = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    parse_all(data)
  end

  def self.parse_all(results)
    # ...
    results.map {|hash| self.new(hash)}
  end

  def self.find(id)
    # ...
    data = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL
    parse_all(data)[0]
  end

  def initialize(params = {})
    # ...
    params.each do |key, value|
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key.to_sym) 
      self.send("#{key}=", value)     
    end
  end

  def attributes
    # ...
    @attributes ||= {}
    
  end

  def attribute_values
    # ...
    @attributes.map { |k,v| v}
  end

  def insert
    values = self.attribute_values
    column_names = self.class.columns.drop(1).join(', ')
    vals = (["?"] * self.attribute_values.length).join(", ")
    # ...
    # debugger
    DBConnection.execute(<<-SQL, *values)
      INSERT INTO 
        #{self.class.table_name} (#{column_names}) 
      VALUES
        (#{vals})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
    values = self.attribute_values.drop(1)
    col_sets = self.class.columns.drop(1).map { |col| "#{col} = ?"}.join(", ") 
    id = self.attributes[:id]
    DBConnection.execute(<<-SQL, *values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_sets}
      WHERE
        id = ?
    SQL
  end

  def save
    # ...
    id = self.attributes[:id]
    self.attribute_values.include?(id) ? self.update : self.insert
  end
end
