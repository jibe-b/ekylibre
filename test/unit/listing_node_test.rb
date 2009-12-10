# == Schema Information
#
# Table name: listing_nodes
#
#  attribute_name       :string(255)   
#  company_id           :integer       not null
#  condition_operator   :string(255)   
#  condition_value      :string(255)   
#  created_at           :datetime      not null
#  creator_id           :integer       
#  exportable           :boolean       default(TRUE), not null
#  id                   :integer       not null, primary key
#  item_listing_id      :integer       
#  item_listing_node_id :integer       
#  item_nature          :string(8)     
#  item_value           :text          
#  key                  :string(255)   
#  label                :string(255)   not null
#  listing_id           :integer       not null
#  lock_version         :integer       default(0), not null
#  name                 :string(255)   not null
#  nature               :string(255)   not null
#  parent_id            :integer       
#  position             :integer       
#  sql_type             :string(255)   
#  updated_at           :datetime      not null
#  updater_id           :integer       
#

require 'test_helper'

class ListingNodeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
