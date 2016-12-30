require 'active_support'
require 'active_support/core_ext'

def value_to_raw(value)
  if value.respond_to? :to_raw
    value.to_raw
  else
    value
  end
end

module CrossDoc

  # convenience methods for storing data in typed fields
  module Fields
    extend ActiveSupport::Concern

    included do
      def assign_fields(attrs)
        # assign simple fields
        if self.class.simple_field_names
          self.class.simple_field_names.each do |field|
            if attrs.has_key? field
              value = attrs.delete field
              self.instance_variable_set "@#{field}", value
            elsif attrs.has_key? field.to_s
              value = attrs.delete field.to_s
              self.instance_variable_set "@#{field}", value
            elsif attrs.has_key? (s=field.to_s.camelize(:lower))
              value = attrs.delete s
              self.instance_variable_set "@#{field}", value
            else
              self.instance_variable_set "@#{field}", nil
            end
          end
        end

        if self.class.object_field_names
          self.class.object_field_names.each do |field|
            self.instance_variable_set "@#{field}", nil
          end
        end

        if self.class.array_field_names
          self.class.array_field_names.each do |field|
            self.instance_variable_set "@#{field}", nil
          end
        end

        # try to assign remaining fields using setters
        attrs.each do |k,v|
          self.send("#{k}=", v)
        end

      end

      # returns a copy of the object that only copies first level references
      def shallow_copy
        new_obj = self.class.new
        new_obj.assign_fields field_values
        new_obj
      end

      # returns a simple hash of all field values
      def field_values
        values = {}
        self.class.all_field_names.each do |f|
          values[f] = self.send(f)
        end
        values
      end

      # returns the object represented as raw ruby hashes and arrays
      def to_raw
        raw = {}

        # simple fields
        (self.class.simple_field_names || []).each do |name|
          v = value_to_raw self.send(name)
          if v
            raw[name] = v
          end
        end

        # array fields
        (self.class.array_field_names || []).each do |name|
          raw[name] = (self.send(name) || []).map {|v| value_to_raw(v)}
        end

        # object fields
        (self.class.object_field_names || []).each do |name|
          v = value_to_raw self.send(name)
          if v
            raw[name] = v
          end
        end

        # hash fields
        (self.class.hash_field_names || []).each do |name|
          h = {}
          (self.send(name) || {}).each do |k, v|
            raw_v = value_to_raw v
            if raw_v
              h[k] = raw_v
            end
          end
          raw[name] = h
        end

        raw
      end
    end

    module ClassMethods
      def simple_fields(fields)
        @simple_field_names = fields
        attr_accessor(*fields)
      end

      attr_reader :simple_field_names, :object_field_names, :array_field_names, :hash_field_names

      def all_field_names
        (self.simple_field_names || []) + (self.object_field_names || []) +
            (self.array_field_names || []) + (self.hash_field_names || [])
      end

      def object_field(name, type)
        unless @object_field_names
          @object_field_names = []
        end
        @object_field_names << name
        define_method name do
          self.instance_variable_get("@#{name}")
        end
        define_method "#{name}=" do |value|
          if value.instance_of? Hash
            value = type.new value
          elsif value.instance_of? type
            # do nothing
          elsif value.nil?
            # do nothing, this is ok
          else
            raise "Invalid type for field #{name}: #{value.class}"
          end
          self.instance_variable_set("@#{name}", value)
        end
      end

      def array_field(name, type)
        unless @array_field_names
          @array_field_names = []
        end
        @array_field_names << name
        define_method name do
          self.instance_variable_get("@#{name}")
        end
        define_method "#{name}=" do |value|
          value = value.map do |v|
            if v.instance_of? Hash
              type.new v
            elsif v.instance_of? type
              v
            else
              raise "Invalid type for field #{name}: #{v.class}"
            end
          end
          self.instance_variable_set("@#{name}", value)
        end
      end

      def hash_field(name, type)
        unless @hash_field_names
          @hash_field_names = []
        end
        @hash_field_names << name
        define_method name do
          self.instance_variable_get("@#{name}")
        end
        define_method "#{name}=" do |value|
          hash = {}
          value.each do |k,v|
            if v.instance_of? Hash
              hash[k] = type.new v
            elsif v.instance_of? type
              hash[k] = v
            else
              raise "Invalid type for #{name}:#{k}: #{v.class}"
            end
          end
          self.instance_variable_set("@#{name}", hash)
        end
      end

    end

  end


  # convenience methods for shadowing a raw hash with accessor methods
  module RawShadow
    extend ActiveSupport::Concern

    included do

      def init_raw(raw)
        @raw = raw
        (self.class.raw_defaults || {}).each do |name, value|
          if value && !@raw.has_key?(name)
            @raw[name] = value.call
          end
        end
      end

    end

    module ClassMethods

      attr_reader :raw_defaults

      def raw_shadow(name, default=nil)
        unless @raw_defaults
          @raw_defaults = {}
        end
        if default
          @raw_defaults[name] = default
        end
        define_method name do
          @raw[name]
        end
        define_method "#{name}=" do |value|
          @raw[name] = value
        end
      end

    end

  end


end