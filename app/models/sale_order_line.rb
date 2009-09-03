# == Schema Information
#
# Table name: sale_order_lines
#
#  account_id          :integer       not null
#  amount              :decimal(16, 2 default(0.0), not null
#  amount_with_taxes   :decimal(16, 2 default(0.0), not null
#  annotation          :text          
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  creator_id          :integer       
#  entity_id           :integer       
#  id                  :integer       not null, primary key
#  invoiced            :boolean       not null
#  label               :text          
#  location_id         :integer       
#  lock_version        :integer       default(0), not null
#  order_id            :integer       not null
#  position            :integer       
#  price_amount        :decimal(16, 2 
#  price_id            :integer       not null
#  product_id          :integer       not null
#  quantity            :decimal(16, 2 default(1.0), not null
#  reduction_origin_id :integer       
#  tax_id              :integer       
#  unit_id             :integer       not null
#  updated_at          :datetime      not null
#  updater_id          :integer       
#

class SaleOrderLine < ActiveRecord::Base
  belongs_to :account
  belongs_to :company
  belongs_to :entity
  belongs_to :location, :class_name=>StockLocation.to_s
  belongs_to :order, :class_name=>SaleOrder.to_s
  belongs_to :price
  belongs_to :product
  belongs_to :reduction_origin, :class_name=>SaleOrderLine.to_s
  belongs_to :tax
  belongs_to :unit
  has_one :reduction, :class_name=>SaleOrderLine.to_s, :foreign_key=>:reduction_origin_id
  has_many :delivery_lines, :foreign_key=>:order_line_id
  has_many :invoice_lines
  acts_as_list :scope=>:order

  attr_readonly :company_id, :order_id
  
  def before_validation
    # check_reservoir = true
    self.product = self.price.product if self.price
    self.account_id = self.product.product_account_id
    self.unit_id = self.product.unit_id
    self.account_id ||= 0
    self.price_amount ||= 0

    reduction_rate = self.order.client.max_reduction_rate

    if self.price_amount > 0
      price = Price.create!(:amount=>self.price_amount, :tax_id=>self.tax.id, :entity_id=>self.company.entity_id , :company_id=>self.company_id, :active=>false, :product_id=>self.product_id, :category_id=>self.order.client.category_id)
      self.price_id = price.id
    end
    
    if self.price 
      if self.reduction_origin_id.nil?
        self.amount = (self.price.amount*self.quantity).round(2)
        self.amount_with_taxes = (self.price.amount_with_taxes*self.quantity).round(2) 
      else
        self.quantity = -reduction_rate*self.reduction_origin.quantity
        self.amount   = -reduction_rate*self.reduction_origin.amount       
        self.amount_with_taxes = -reduction_rate*self.reduction_origin.amount_with_taxes
      end
    end

    if self.reduction_origin_id.nil?
      self.label = self.product.catalog_name
    else
      self.label = tc('reduction_on', :product=>self.product.catalog_name, :rate=>reduction_rate, :percent=>reduction_rate*100, :amount=>self.amount_with_taxes-self.reduction_origin.amount_with_taxes)
    end
    
    #     if self.location.reservoir && self.location.product_id != self.product_id
    #       check_reservoir = false
    #       errors.add_to_base(tc(:stock_location_can_not_transfer_product), :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name, :account_id=>0, :unit_id=>self.unit_id) 
    #     end
    #     check_reservoir
  end

  
  def after_save
    reduction_rate = self.order.client.max_reduction_rate
    if reduction_rate > 0 and self.product.reduction_submissive and self.reduction_origin_id.nil?
      reduction = self.reduction || self.build_reduction
      reduction.attributes = {:company_id=>self.company_id, :reduction_origin_id=>self.id, :price_id=>self.price_id, :product_id=>self.product_id, :order_id=>self.order_id, :location_id=>self.location_id, :quantity=>-self.quantity*reduction_rate}
      reduction.save!
    elsif self.reduction
      self.reduction.destroy
    end
    self.order.reload.refresh if self.reduction_origin.nil?
  end
  
  def after_destroy
    self.reduction.destroy if self.reduction
    self.order.refresh
  end

  def validate
    errors.add_to_base(tc(:stock_location_can_not_transfer_product), :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name) unless self.location.can_receive?(self.product_id)
    errors.add_to_base(tc(:currency_is_not_sale_order_currency)) if self.price.currency_id != self.order.currency_id
  end
  
  def undelivered_quantity
    self.quantity - self.delivery_lines.sum(:quantity)
  end

  def product_name
    self.product ? self.product.name : tc(:no_product) 
  end

  def designation
    d  = self.label
    d += "\n"+self.annotation.to_s unless self.annotation.blank?
    d
  end

  def subscription?
    self.product.nature == "subscrip"
  end

  def taxes
    self.amount_with_taxes - self.amount
  end

end
