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
    require "puppet/util/windows/registry"
    include Puppet::Util::Windows::Registry

    # Define the constants if they're not already available
    KEY_READ = 0x20019 unless defined?(KEY_READ)
    KEY_WOW64_64KEY = 0x0100 unless defined?(KEY_WOW64_64KEY)

    installed_packages = {}

    def each_installed_package
      hives = ["HKEY_LOCAL_MACHINE", "HKEY_CURRENT_USER"]
      paths = ['Software\Microsoft\Windows\CurrentVersion\Uninstall', 'Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall']
      hives.each do |hive|
        paths.each do |path|
          begin
            open(hive, path, KEY_READ | KEY_WOW64_64KEY) do |uninstall_key|
              each_key(uninstall_key) do |subkey_name, _|
                open(uninstall_key, subkey_name, KEY_READ) do |key|
                  yield key
                end
              end
            end
          rescue Puppet::Util::Windows::Error => e
            next if e.code == Puppet::Util::Windows::Error::ERROR_FILE_NOT_FOUND
          end
        end
      end
    end

    each_installed_package do |key|
      displayname = key["DisplayName"] rescue nil
      version = key["DisplayVersion"] rescue nil
      uninstallpath = key["UninstallString"] rescue nil
      systemcomponent = key["SystemComponent"] rescue nil
      installdate = key["InstallDate"] rescue nil

      if displayname && uninstallpath && systemcomponent.to_i != 1
        installed_packages[displayname] = {
          "version" => version,
          "installdate" => installdate,
        }
      end
    end

    installed_packages
  end
end
