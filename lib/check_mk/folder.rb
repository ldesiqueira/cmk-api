class Check_MK
  class Folder
    def initialize(parent, name)
      @parent, @name = parent, name
    end

    def hosts
      @parent.list_hosts(@name)
    end
  end
end
