module PeopleHelper

  def birthday_date(person)
    if person.birthday.day == Date.today.day && person.birthday.month == Date.today.month
       "#{l(:label_today).capitalize}"
    else
      "#{person.birthday.day} #{t('date.month_names')[person.birthday.month]}"
    end
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

  def block_cfo_edit?(person)
    not User.current.allowed_people_to?(:edit_people, person)
  end

  def default_leader(person)
    begin
      leader = Person.find_by_id(Person.find_by_id(User.current.id).department.head_id)
      puts "!!!!!111111"
      puts leader.lastname + ' ' + leader.firstname
      puts "!!!!!222222"
      leader.lastname + ' ' + leader.firstname
    rescue
      nil
    end
  end

  def principals_options_for_select(collection, selected=nil)
    s = ''
    if collection.include?(User.current)
      s << content_tag('option', "<< #{l(:label_me)} >>", :value => User.current.id)
    end
    groups = ''
    collection.sort.each do |element|
      selected_attribute = ' selected="selected"' if element.to_s.eql? selected
      (element.is_a?(Group) ? groups : s) << %(<option value="#{element.id}"#{selected_attribute}>#{h element.name}</option>)
    end
    unless groups.empty?
      s << %(<optgroup label="#{h(l(:label_group_plural))}">#{groups}</optgroup>)
    end
    s.html_safe
  end

end
