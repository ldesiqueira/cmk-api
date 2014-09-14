class Check_MK
  class Wato
    class Folder
      # A list of all the hosts defined in the current folder
      def hosts
        # Crude heuristic that expects hosts to resemble this:
        #
        # all_hosts += [
        #   "localhost|cmk-agent|prod|lan|tcp|wato|/" + FOLDER_PATH + "/",
        #   ]
        res = []
        infile = @path + '/hosts.mk'
        File.open(infile).readlines.each do |line|
          if line =~ /\|wato\|.* \+ FOLDER_PATH \+/
  	  line =~ / \"(.*?)\|/
            raise "syntax error reading #{infile}; line=#{line}" unless $1
  	  res.push $1
  	end
        end
        res
      end
  
      def initialize(path)
        raise ArgumentError, "bad path: #{path}" unless File.exist? path
        @path = path
      end
    end
  
    # Return a list of all WATO folders
    def folders
      res = []
      `find #{@confdir} -name hosts.mk`.each do |ent|
         found = File.dirname(ent).gsub(/.*\//, '')
         # Special case: the main directory
         res.push found unless found == 'wato'
      end
      res.sort
    end
  
    # Get a handle to a specific folder
    # [+name+] the name of the folder
    def folder(name)
      Folder.new(@confdir + '/' + name)
    end
  
    # Return a list of all hosts in all WATO folders
    def hosts
      res = []
      folders.each do |f|
        res.concat folder(f).hosts
      end
      res.sort
    end
  
    # e.g.
    #/omd/sites/devstage/etc/check_mk/conf.d/wato
    def initialize(prefix)
      raise 'invalid prefix' unless File.exist? prefix
      @prefix = prefix
      @confdir = prefix + '/etc/check_mk/conf.d/wato'
    end
  end
end
