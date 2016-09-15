# unlike the rest of this library, which is new code, the code in this source file is from ActiveRecord, and
# is used to provide compatibility wrappers with different versions of ActiveRecord.  please keep it separate
# so we can see where everything came from and what may need to be kept in sync with ActiveRecord refactors.
module OnForm
  module MultiparameterAttributes
    # Instantiates objects for all attribute classes that needs more than one constructor parameter. This is done
    # by calling new on the column type or aggregation type (through composed_of) object with these parameters.
    # So having the pairs written_on(1) = "2004", written_on(2) = "6", written_on(3) = "24", will instantiate
    # written_on (a date type) with Date.new("2004", "6", "24"). You can also specify a typecast character in the
    # parentheses to have the parameters typecasted before they're used in the constructor. Use i for Integer and
    # f for Float. If all the values for a given attribute are empty, the attribute will be set to +nil+.
    def assign_multiparameter_attributes(pairs)
      execute_callstack_for_multiparameter_attributes(
        extract_callstack_for_multiparameter_attributes(pairs)
      )
    end

    def execute_callstack_for_multiparameter_attributes(callstack)
      errors = []
      callstack.each do |name, values_with_empty_parameters|
        begin
          if defined?(ActiveRecord::AttributeAssignment::MultiparameterAttribute)
            # ActiveRecord 4.2 and below: you must use MultiparameterAttribute to construct the attribute value.
            # we therefore have to look up which model the attribute actually lives on.
            send("#{name}=", ActiveRecord::AttributeAssignment::MultiparameterAttribute.new(backing_object_for_attribute(name), name, values_with_empty_parameters).read_value)
          else
            # ActiveRecord 5.0+: you can assign the indexed hash to the column and it will construct the value for you.
            if values_with_empty_parameters.each_value.all?(&:nil?)
              values = nil
            else
              values = values_with_empty_parameters
            end
            send("#{name}=", values)
          end
        rescue => ex
          errors << ActiveRecord::AttributeAssignmentError.new("error on assignment #{values_with_empty_parameters.values.inspect} to #{name} (#{ex.message})", ex, name)
        end
      end
      unless errors.empty?
        error_descriptions = errors.map(&:message).join(",")
        raise ActiveRecord::MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes [#{error_descriptions}]"
      end
    end

    def extract_callstack_for_multiparameter_attributes(pairs)
      attributes = {}

      pairs.each do |(multiparameter_name, value)|
        attribute_name = multiparameter_name.split("(").first
        attributes[attribute_name] ||= {}

        parameter_value = value.empty? ? nil : type_cast_attribute_value(multiparameter_name, value)
        attributes[attribute_name][find_parameter_position(multiparameter_name)] ||= parameter_value
      end

      attributes
    end

    def type_cast_attribute_value(multiparameter_name, value)
      multiparameter_name =~ /\([0-9]*([if])\)/ ? value.send("to_" + $1) : value
    end

    def find_parameter_position(multiparameter_name)
      multiparameter_name.scan(/\(([0-9]*).*\)/).first.first.to_i
    end
  end
end
