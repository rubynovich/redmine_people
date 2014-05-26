module RedminePeople
  module Patches
    module TimeReportHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :load_available_criteria, :people
          alias_method_chain :run, :people
        end
      end


      module InstanceMethods

        private

        def load_available_criteria_with_people
          @available_criteria = load_available_criteria_without_people
          @available_criteria.merge!({ 'cfo' => {:sql => "#{User.table_name}.cfo_id",
                                                     :klass => Cfo,
                                                     :label => :label_cfo}})
          @available_criteria
        end

        def run_with_people
          @scope = @scope.includes(:user)
          run_without_people
        end

      end

    end
  end
end

