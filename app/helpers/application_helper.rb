module ApplicationHelper
  def title(value)
    unless value.nil?
      @title = "#{value} | Conquest"      
    end
  end
end
