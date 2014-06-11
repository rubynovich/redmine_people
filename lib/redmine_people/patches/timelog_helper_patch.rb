module RedminePeople
  module Patches
    module TimelogHelperPatch
      unloadable
      extend ActiveSupport::Concern
      included do
        alias_method_chain :format_criteria_value, :people
      end
      # def x(criteria_options, value)
      #   if value.blank?
      #     "[#{l(:label_none)}]"
      #   elsif k = criteria_options[:klass]
      #     obj = k.find_by_id(value.to_i)
      #     if obj.is_a?(Issue)
      #       obj.visible? ? "#{obj.tracker} ##{obj.id}: #{obj.subject}" : "##{obj.id}"
      #     else
      #       obj
      #     end
      #   elsif cf = criteria_options[:custom_field]
      #     format_value(value, cf)
      #   else
      #     value.to_s
      #   end
      # end


      def format_criteria_value_with_people(criteria_options, value)

        if (criteria_options[:klass] == Cfo) && value.to_s == '0'
          "[#{l(:label_none)}]"
        else
          format_criteria_value_without_people(criteria_options, value)
        end
      end
    end
  end
end
