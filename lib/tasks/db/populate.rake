namespace :db do
  desc 'Populate database with fake data for development'
  task :populate => [ 'db:seed', 'db:populate:create' ]

  namespace :populate do

    desc "Reload populate data"
    task :reload => [ 'db:reset', :create ]

    desc "Create populate data"
    task :create => :environment do

      LOGOS_PATH = File.join(Rails.root, 'lib', 'logos')

      def set_logos(klass)
        klass.all.each do |i|
          logo = Dir[File.join(LOGOS_PATH, klass.to_s.tableize, "#{ i.id }.*")].first

          if File.exist?(logo)
            i.logo = File.new(logo)
            i.logo.reprocess!
            i.save!
          end
        end
      end

      # = Users

      # Create demo user if not present
      if User.find_by_name('demostration').blank?
        User.create! :name => 'demostration',
                     :email => 'demostration@test.com',
                     :password => 'demostration',
                     :password_confirmation => 'demostration'
      end

      9.times do
        User.create! :name => Forgery::Name.full_name,
                     :email => Forgery::Internet.email_address,
                     :password => 'demostration',
                     :password_confirmation => 'demostration'
      end

      set_logos(User)

      available_users = User.all

      # = Groups
      10.times do
        Group.create :name  => Forgery::Name.company_name,
                     :email => Forgery::Internet.email_address
      end

      set_logos(Group)

      available_groups = Group.all

      # = Ties
      available_users.each do |u|
        users = available_users.dup - Array(u)
        user_relations = %w( Friend ).map{ |r| Relation.mode('User', 'User').find_by_name(r) }

        Forgery::Basic.number.times do
          user = users.delete_at((rand * users.size).to_i)
          u.ties.create :receiver => user.actor,
                        :relation => user_relations.random
        end
        groups = available_groups.dup
        group_relations = Relation.mode('User', 'Group')

        Forgery::Basic.number.times do
          group = groups.delete_at((rand * groups.size).to_i)
          u.ties.create :receiver => group.actor,
                        :relation => group_relations.random
        end
      end
    end
  end
end
