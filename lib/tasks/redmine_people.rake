namespace :redmine do
  namespace :plugins do
    desc 'Copies city from address to city in redmine_people.'
    task :people_update_city => :environment do
    	Person.all.each do |p|
        	if p.address && p.address.include?("Москва")
                p.city = 1
    			p.update_attribute(:city, 1)
                puts p.city
    		elsif p.address && p.address.include?("Санкт")
    			p.update_attribute(:city, 2)
                puts p.city
            else
                p.city = 0
    		end
    	end
    end
  end
end