module RedminePeople
  module Patches
    module TimeEntryQueryPatch
      unloadable
      extend ActiveSupport::Concern
      included do
        alias_method_chain :initialize_available_filters, :people
        alias_method_chain :initialize, :people
        alias_method_chain :statement, :people
        #alias_method_chain :results_scope, :people
        self.available_columns << QueryColumn.new(:cfo_id, :sortable => "#{User.table_name}.cfo_id", :groupable => true)
      end


      def initialize_with_people(attributes=nil, *args)
        initialize_without_people(attributes, args)
        #self.filters ||= {}
        #add_filter('cfo_id', '*') unless filters.present?
      end

      def initialize_available_filters_with_people
        add_available_filter("cfo_id",
          :type => :list, :values => [["<#{t(:label_none)}>",nil]] + Cfo.all.sort.map {|a| ["#{a.cfo_slug} (#{a.cfo})", a.id.to_s]}, :label => :label_cfo
        ) unless Cfo.count == 0
        initialize_available_filters_ without_people
      end


      #def results_scope_with_people(options={})
      #  results_scope_without_people(options).includes(:user)
      #end

      def statement_with_people
        res = statement_without_people
        res.gsub('time_entries.cfo_id', 'users.cfo_id')
      end

    end
  end
end