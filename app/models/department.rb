# coding: utf-8
class Department < ActiveRecord::Base
  include Redmine::SafeAttributes
  unloadable
  belongs_to :head, :class_name => 'Person', :foreign_key => 'head_id'    
  has_many :people, :uniq => true, :dependent => :nullify

  belongs_to :default_internal_role, class_name: 'Role', foreign_key: 'default_internal_role_id'
  belongs_to :default_external_role, class_name: 'Role', foreign_key: 'default_external_role_id'
  
  acts_as_nested_set :order => 'name', :dependent => :destroy
  acts_as_attachable_global

  validates_presence_of :name 
  validates_uniqueness_of :name 

  safe_attributes 'name',
                  'background',
                  'parent_id',
                  'head_id',
                  'default_internal_role_id',
                  'default_external_role_id'

  after_initialize :stash_default_external_role
  after_save  :update_default_roles_in_projects
  
  def to_s
    name
  end

  # Yields the given block for each department with its level in the tree
  def self.department_tree(departments, &block)
    ancestors = []
    departments.sort_by(&:lft).each do |department|
      while (ancestors.any? && !department.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield department, ancestors.size
      ancestors << department
    end
  end  

  def css_classes
    s = 'project'
    s << ' root' if root?
    s << ' child' if child?
    s << (leaf? ? ' leaf' : ' parent')
    s
  end

  def allowed_parents
    return @allowed_parents if @allowed_parents
    @allowed_parents = Department.all
    @allowed_parents = @allowed_parents - self_and_descendants
    @allowed_parents << nil
    unless parent.nil? || @allowed_parents.empty? || @allowed_parents.include?(parent)
      @allowed_parents << parent
    end
    @allowed_parents
  end  

  def stash_default_external_role
    @old_default_external_role = self.default_external_role
    # Rails.logger.error("заначили старую роль #{@old_default_external_role.try(:name)}".yellow)
  end
  
  # При изменении ролей по умолчанию заменяет во всех текущих проектах
  # роли для уже добавленных людей из этого подразделения на новое, указанное значение.
  def update_default_roles_in_projects
    Rails.logger.error("запуск колбека".yellow)
    # if @old_default_external_role && @old_default_external_role != default_external_role
    #   Rails.logger.error("меняем роль".yellow)
    #   Rails.logger.error("старая: #{@old_default_external_role}".yellow)
    #   Rails.logger.error("новая: #{default_external_role.name}".yellow)
    #   for person in self.people
    #     for project in person.projects.select{|p| p.is_external}
    #       if person.roles_for_project(project).include?(@old_default_external_role)
    #         Rails.logger.error(" #{person} добавлен в проект ##{project.id} с ролью #{ @old_default_external_role.try(:name) }".yellow)
    #         member = Member.where(project_id: project.id, user_id: person.id).first
    #         Rails.logger.error("#{member.inspect}".yellow)
    #         Rails.logger.error("добавляем новую роль".yellow)
    #         member.roles << default_external_role
    #         member.reload
    #         member_role = member.member_roles.where(role_id: @old_default_external_role.id).first
    #         Rails.logger.error("#{member_role.inspect}".yellow)
    #         Rails.logger.error("до удаления: #{member.roles.map{|r| r.name}.to_s}".yellow)
    #         member_role.destroy
    #         member.reload
    #         Rails.logger.error("после удаления: #{member.roles.map{|r| r.name}.to_s}".yellow)
    #         Rails.logger.error("после замены роли: #{member.roles.map{|r| r.name}.to_s}".yellow)
    #       end
    #     end
    #   end 
    # end
  end
  
end
