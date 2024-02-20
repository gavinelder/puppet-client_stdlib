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

