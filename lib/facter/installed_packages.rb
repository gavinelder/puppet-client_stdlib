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

Facter.add("installed_packages") do
  confine :kernel => "windows"
  setcode do
    require 'puppet/util/windows/registry'

    installed_packages = {}

    # Use Puppet::Util::Windows::Registry to get the installed packages
    Puppet::Util::Windows::Registry.open(HKEY_LOCAL_MACHINE, 'Software\Microsoft\Windows\CurrentVersion\Uninstall', Win32::Registry::KEY_READ | 0x100) do |reg|
      reg.each_key do |key, _|
        begin
          installed_packages[key] = Puppet::Util::Windows::Registry.getkeys(HKEY_LOCAL_MACHINE, "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\#{key}")
        rescue
          next
        end
      end
    end

    installed_packages
  end
end
