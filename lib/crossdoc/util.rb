require 'active_support'
require 'active_support/core_ext'

module CrossDoc

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
            end
          end
        end

        # try to assign remaining fields using setters
        attrs.each do |k,v|
          self.send("#{k}=", v)
        end

      end
    end

    class_methods do
      def simple_fields(fields)
        @simple_field_names = fields
        attr_accessor *fields
      end

      attr_reader :simple_field_names

      def object_field(name, type)
        define_method name do
          self.instance_variable_get("@#{name}")
        end
        define_method "#{name}=" do |value|
          if value.instance_of? Hash
            value = type.new value
          elsif value.instance_of? type
            # do nothing
          else
            raise "Invalid type for field #{name}: #{value.class}"
          end
          self.instance_variable_set("@#{name}", value)
        end
      end

      def array_field(name, type)
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


end