# == Schema Information
#
# Table name: roles
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#  rights       :text          
#

class Role < ActiveRecord::Base
  belongs_to :company
  has_many :users

  attr_readonly :company_id

  ACTIONS =  [ :all,                     # All
              :accountancy,             # Accountant
              :sales                    # Saler
            ]

  #set_column :actions, ACTIONS

  def before_validation
    # self.actions_array = self.actions_array # Refresh actions array
  end

  def before_update
    old_rights_array = []
    new_rights_array = []
    old_rights = Role.find_by_id_and_company_id(self.id, self.company_id).rights.to_s.split(" ")
    
    for right in old_rights
      old_rights_array << right.to_sym
    end
    for right in self.rights.split(" ")
      new_rights_array << right.to_sym
    end

    added_rights = new_rights_array-old_rights_array
    deleted_rights = old_rights_array- new_rights_array
    
    users = User.find_all_by_role_id_and_company_id_and_admin(self.id, self.company_id, false)
    for user in users
      puts user.rights.inspect
      user_rights_array = []
      for right in user.rights.split(" ")
        user_rights_array << right.to_sym
      end
      
      user_rights_array.delete_if {|r| deleted_rights.include?(r) }
      for added_right in added_rights
        user_rights_array << added_right unless user_rights_array.include?(added_right)
      end
         
      user.rights = ""
        for right in user_rights_array
          user.rights += right.to_s+" "
        end
      user.save
      puts user.rights.inspect
    end
  end



#  def can_do?(action=:all)
#    return self.actions_include?(:all) ? true : self.actions_include?(action)
#  end

  def can_do(action)
    #self.actions_set(action)
    #self.save!
  end

  def cannot_do(action)
    #self.actions_set(action, false)
    #self.save!
  end

  def action_name(action)
    lc(action.to_sym)
  end

#    raise Exception.new('Can\'t evaluate action: nil') if action.nil?
#    action = Action.find_by_name(action.to_s) unless action.is_a? Action
#    self.action_ids.include? action.id
#  end

end
