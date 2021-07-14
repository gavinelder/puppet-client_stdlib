# frozen_string_literal: true

Facter.add("installed_packages") do
  confine osfamily: "Darwin"
  setcode do
    require "puppet/util/plist"

    items = {}

    output = Facter::Util::Resolution.exec("/usr/sbin/pkgutil --regexp --pkg-info-plist '.*'")

    pkginfos = output.split("\n\n\n")

    pkginfos.each do |pkginfo|
      data = Puppet::Util::Plist.parse_plist(pkginfo)
      pkgid = data["pkgid"]
      items[pkgid.encode("iso-8859-1", undef: :replace, replace: "")] = {
        "version" => data["pkg-version"],
        "installtime" => data["install-time"],
        "installlocation" => data["install-location"],
        "volume" => data["volume"],
      }
    end

    items
  end
end

# yes, windows machines exist
# set to break if powershell cannot be found at the defined path
Facter.add("installed_packages") do
  confine osfamily: "Windows"

  setcode do
    if Facter.value(:os)["release"]["full"].to_i >= 10
      # Loop through all uninstall keys for 64bit applications.  
      Win32::Registry::HKEY_LOCAL_MACHINE.open('Software\Microsoft\Windows\CurrentVersion\Uninstall') do |reg|
        reg.each_key do |key|
                
        k = reg.open(key)
        
        displayname     = k["DisplayName"] rescue nil
        version         = k["DisplayVersion"] rescue nil      
        uninstallpath   = k["UninstallString"] rescue nil
        systemcomponent = k["SystemComponent"] rescue nil

        if(displayname && uninstallpath)
            unless(systemcomponent == 1)
              unless(displayname.match(/[KB]{2}\d{7}/)) # excludes windows updates
                software_list << {DisplayName: displayname, Version: version }
              end
            end
        end

        end
      end
end
