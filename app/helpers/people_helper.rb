module PeopleHelper

  def birthday_date(person)
    if person.birthday.day == Date.today.day && person.birthday.month == Date.today.month
       "#{l(:label_today).capitalize}"
    else
      "#{person.birthday.day} #{t('date.month_names')[person.birthday.month]}"
    end
  end

  def city_options_for_select
    options_for_select(Person::CITIES.to_a, @person[:city])

  end

  def person_to_vcard(person)  
    require 'vpim/vcard'

    card = Vpim::Vcard::Maker.make2 do |maker|

      maker.add_name do |name|
        name.prefix = ''
        name.given = person.firstname.to_s
        name.family = person.lastname.to_s
        name.additional = person.middlename.to_s
      end

      maker.add_addr do |addr|
        addr.preferred = true
        addr.street = person.address.to_s.gsub("\r\n"," ").gsub("\n"," ")
      end
      
      maker.title = person.job_title.to_s
      maker.org = person.company.to_s   
      maker.birthday = person.birthday.to_date unless person.birthday.blank?
      maker.add_note(person.background.to_s.gsub("\r\n"," ").gsub("\n", ' '))
       
      # maker.add_url(person.website.to_s)

      person.phones.each { |phone| maker.add_tel(phone) }
      
      maker.add_email(person.email)
    end   
    avatar = person.avatar  
    card = card.encode.sub("END:VCARD", "PHOTO;BASE64:" + "\n " + [File.open(avatar.diskfile).read].pack('m').to_s.gsub(/[ \n]/, '').scan(/.{1,76}/).join("\n ") + "\nEND:VCARD") if avatar && avatar.readable?
    card.to_s   
    
  end

  def default_leader(person)
    begin
      leader = person.department.head_id
      leader.lastname + ' ' + leader.firstname
    rescue
      nil
    end
  end


  def block_cfo_edit?(person)
    not User.current.allowed_people_to?(:edit_people, person)
  end

  def block_leader_edit?(person)
    not User.current.allowed_people_to?(:edit_people, person)
  end

  def principals_options_for_select_in_person(collection, selected=nil)
    collection ||= []
    s = ''
    if collection.include?(User.current)
      s << content_tag('option', "<< #{l(:label_me)} >>", :value => User.current.id)
    end
    groups = ''
    collection.sort.each do |element|
      selected_attribute = ' selected="selected"' if option_value_selected?(element, selected)
      (element.is_a?(Group) ? groups : s) << %(<option value="#{element.id}"#{selected_attribute}>#{h element.name}</option>)
    end
    unless groups.empty?
      s << %(<optgroup label="#{h(l(:label_group_plural))}">#{groups}</optgroup>)
    end
    s.html_safe
  end

  def person_current_leader person
    begin
      current_leader = Principal.find_by_id(User.find_by_id(person.id).leader_id)
      if current_leader.nil?
        current_department = Department.find_by_id(User.find_by_id(person.id).department_id)
        current_leader = Principal.find_by_id(Department.find_by_id(User.find_by_id(person.id).department_id).head_id)
        if current_leader.id == person.id
          current_leader = Principal.find_by_id(current_department.parent.head_id)
        end
      end
      current_leader
    rescue
      nil
    end
  end

  def person_current_cfo person
    begin
      current_cfo = Cfo.find_by_id(User.find_by_id(person.id).cfo_id)
      current_cfo.id
    rescue
      nil
    end
  end

end
