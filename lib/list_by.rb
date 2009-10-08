module ListBy
  module ClassMethods
    def list_by(attribute, options = {})      
      named_scope :list_members_for, lambda { |instance| { :conditions => instance.list_conditions } }
      
      class_eval %{
        def list_conditions
          { #{[ options[:scope] ].compact.flatten.map { |column| ":#{column} => #{column}" }.join(", ")} }
        end
        
        def list_members
          self.class.list_members_for(self)
        end
        
        def add_to_end_of_list
          self.#{attribute} ||= self.class.list_members_for(self).count
        end

        def reorder_list
          return unless #{attribute}_changed?
          old_attribute = #{attribute}_was || list_members.count
          range, operator = #{attribute} > old_attribute ? [ old_attribute + 1 .. #{attribute}, "-" ] : [ #{attribute} ... old_attribute, "+" ]
          list_members.scoped(:conditions => { :#{attribute} => range }).update_all("#{attribute} = #{attribute} \#{operator} 1")
        end
        
        def remove_from_list
          range = #{attribute} + 1 ... list_members.count
          list_members.scoped(:conditions => [ "#{attribute} > :#{attribute}", { :#{attribute} => #{attribute} } ]).update_all("#{attribute} = #{attribute} - 1")
        end
        
        def <=>(other)
          #{attribute} <=> other.#{attribute}
        end
      }
      
      before_validation_on_create :add_to_end_of_list
      
      validates_numericality_of attribute
      
      instance_eval %{
        validate do |instance|
          range = instance.new_record? ? 0..list_members_for(instance).count : 0...list_members_for(instance).count
          instance.errors.add(attribute, :is_not_in_range) unless range.include?(instance.#{attribute})
        end
      }
      
      before_save :reorder_list
      after_destroy :remove_from_list
      
      default_scope :order => attribute
    end
  end
end

ActiveRecord::Base.extend ListBy::ClassMethods