require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.singularize.constantize
  end

  def table_name
    if self.class_name == "Human"
      "humans"
    else
      self.class_name.tableize
    end
  end
end

class BelongsToOptions < AssocOptions

  def initialize(name, options = {})
    if options.has_key?(:foreign_key)
      @foreign_key = options[:foreign_key]
    else
      @foreign_key = (name.to_s + "Id").camelcase.underscore.to_sym
    end

    if options.has_key?(:class_name)
      @class_name = options[:class_name]
    else
      @class_name = name.to_s.singularize.capitalize
    end

    if options.has_key?(:primary_key)
      @primary_key = options[:primary_key]
    else
      @primary_key = :id
    end

  end

end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    if options.has_key?(:foreign_key)
      @foreign_key = options[:foreign_key]
    else
      @foreign_key = (self_class_name.to_s + "Id").camelcase.underscore.to_sym
    end

    if options.has_key?(:class_name)
      @class_name = options[:class_name]
    else
      @class_name = name.to_s.singularize.capitalize
    end

    if options.has_key?(:primary_key)
      @primary_key = options[:primary_key]
    else
      @primary_key = :id
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    association = BelongsToOptions.new(name,options)

    self.assoc_options[name] = association

    define_method(name) do
      association.model_class.send(
        :where,
        { association.primary_key => self.send(association.foreign_key) }
        ).first
    end

  end

  def has_many(name, options = {})
    association = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      association.class_name.constantize.send(
        :where, { association.foreign_key => self.id } )
    end

  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
  attr_accessor :assoc_options
end
