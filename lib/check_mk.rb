class Check_MK
  require 'check_mk/wato'

  # Return a list of all the sites on this machine
  def sites
    Dir.glob('/opt/omd/sites/*').sort.map { |x| File.basename(x) }
  end

  # Return a handle to a specific site
  # [+name+] the name of the site
  def site(name)
    raise ArgumentError, 'site not found' unless sites.include? name
    Check_MK::Wato.new('/opt/omd/sites/' + name)
  end
end
