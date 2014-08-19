class Wato
  class Folder
    # Delete a host from a folder
    # [+name+] the name of the host
    def delete_host(name)
      unless hosts.include? name
        raise ArgumentError, "host `#{name}' does not exist"
      end
      srcfile = @path + '/hosts.mk'
      tmpfile = srcfile + '.tmp' + $$.to_s
      begin
        f1 = File.open(srcfile)
        f2 = File.open(tmpfile, 'w')
	f1.readlines.each do |line|
	  f2.puts(line) unless line =~ / \"#{name}\|/
	end
	f1.close
	f2.close
	File.rename(tmpfile, srcfile)
      rescue
        File.delete(tmpfile)
      end
      nil
    end

    # Add a host to a folder
    # [+name+] the name of the host
    # [+tags+] the tags to use (optional)
    def add_host(name, tags = 'cmk-agent|prod|lan|tcp|wato')
      if hosts.include? name
        raise ArgumentError, "host `#{name}' already exists"
      end

      f = File.open(@path + '/hosts.mk', 'a')
      f.puts '# added by the watome tool'
      f.puts "all_hosts += [ \"#{name}|#{tags}|/\" + FOLDER_PATH + \"/\" ]"
      f.puts "host_attributes.update({'#{name}': {}})"
      f.close
      nil
    end
    
    # A list of all the hosts defined in the current folder
    def hosts
      # Crude heuristic that expects hosts to resemble this:
      #
      # all_hosts += [
      #   "localhost|cmk-agent|prod|lan|tcp|wato|/" + FOLDER_PATH + "/",
      #   ]
      res = []
      File.open(@path + '/hosts.mk').readlines.each do |line|
        if line =~ / \+ FOLDER_PATH \+/
	  line =~ / \"(.*?)\|/
          raise 'syntax error' unless $1
	  res.push $1
	end
      end
      res
    end

    def initialize(path)
      raise ArgumentError, 'bad path' unless File.exist? path
      @path = path
    end
  end

  # Return a list of all WATO folders
  def folders
    res = []
    `find #{@confdir} -name hosts.mk`.each do |ent|
       res.push File.dirname(ent).gsub(/.*\//, '')
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
