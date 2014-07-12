# encoding: utf-8
class Department < ActiveRecord::Base
  include Redmine::SafeAttributes
  unloadable
  belongs_to :head, :class_name => 'Person', :foreign_key => 'head_id'    
  has_many :people, :uniq => true, :dependent => :nullify

  belongs_to :default_internal_role, class_name: 'Role', foreign_key: 'default_internal_role_id'
  belongs_to :default_external_role, class_name: 'Role', foreign_key: 'default_external_role_id'

  belongs_to :confirmer, class_name: 'Person'
  
  acts_as_nested_set :order => 'name', :dependent => :destroy
  acts_as_attachable_global

  validates_presence_of :name 
  validates_uniqueness_of :name 

  validates_presence_of :default_internal_role
  validates_presence_of :default_external_role

  safe_attributes 'name',
                  'background',
                  'parent_id',
                  'head_id',
                  'confirmer_id',
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

  def confirmer
    conf = super
    unless conf
      self.update_column(:confirmer_id, find_head.id)
    end
    conf
  end

  def find_head
    self.head ? self.head : self.parent.find_head
  end

  def parents_department_heads
    heads = [self.find_head]
    if self.parent_id
      heads += self.parent.parents_department_heads
    end
    heads.compact.uniq
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
    @old_default_internal_role = self.default_internal_role
    @old_default_external_role = self.default_external_role
    # Rails.logger.error("заначили старую роль #{@old_default_external_role.try(:name)}".yellow)
  end
  
  # При изменении ролей по умолчанию заменяет во всех текущих проектах
  # роли для уже добавленных людей из этого подразделения на новое, указанное значение.
  def update_default_roles_in_projects
    Rails.logger.error("запуск колбека".light_green)
    if (@old_default_external_role && @old_default_external_role != default_external_role) || (@old_default_internal_role && @old_default_internal_role != default_internal_role)
      Rails.logger.error("меняем роль".light_green)

      Rails.logger.error("старая внутренняя роль: #{@old_default_internal_role}".light_green)
      Rails.logger.error("новая: внутренняя роль: #{default_internal_role.name}".light_green)
      Rails.logger.error("старая внешняя роль: #{@old_default_external_role}".light_green)
      Rails.logger.error("новая: внешняя роль: #{default_external_role.name}".light_green)

      for person in self.people
        for project in person.projects
          roles_for_project = person.roles_for_project(project)
          if roles_for_project.include?(@old_default_internal_role) || roles_for_project.include?(@old_default_external_role)
             
            Rails.logger.error(" #{person} добавлен в проект ##{project.id} с ролью #{ @old_default_external_role.try(:name) }".light_green)
            member = Member.where(project_id: project.id, user_id: person.id).first
            Rails.logger.error("#{member.inspect}".light_green)

            Rails.logger.error("до замены ролей: #{member.roles.map{|r| r.name}.to_s}".light_green)
            if project.is_external? && @old_default_external_role != default_external_role
              Rails.logger.error("!!! меняем роль для внешних проектов".light_green)
              member.roles << default_external_role
              member.roles = member.roles - [@old_default_external_role]
            end

            if !project.is_external? && @old_default_internal_role != default_internal_role
              Rails.logger.error("!!! меняем роль для внутренних проектов".light_green)
              member.roles << default_internal_role
              member.roles = member.roles - [@old_default_internal_role]
            end
            Rails.logger.error("после замены ролей: #{member.roles.map{|r| r.name}.to_s}".light_green)

          end
        end
      end 
    end
  end
  
end
