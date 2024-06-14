# frozen_string_literal: true

# vim: syntax=ruby tabstop=2 softtabstop=2 shiftwidth=2

require 'rexml/document'

gluster_peers = {}
gluster_volumes = {}
peer_count = 0
peer_list = ''
peer_list_ar = []
volume_options = {}
volume_ports = {}

binary = Facter.value('gluster_custom_binary')
# rubocop:disable Style/AndOr
if !binary or !File.executable? binary
  # rubocop:enable Style/AndOr
  # http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby/5471032#5471032
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "gluster#{ext}")
      binary = exe if File.executable? exe
    end
  end
end

if binary
  # Gluster facts don't make sense if the Gluster binary isn't present

  # The Gluster binary command to use
  Facter.add(:gluster_binary) do
    setcode do
      binary
    end
  end

  # Get our peer information from gluster peer status --xml (Code credit to github user: coder-hugo)
  peer_status_xml = REXML::Document.new(Facter::Util::Resolution.exec("#{binary} peer status --xml"))
  REXML::XPath.match(peer_status_xml, '/cliOutput/peerStatus/peer').each do |peer_xml|
    # Get the peer hostname
    peer = peer_xml.elements['hostname'].text.to_s

    # Define a per-peer hash to contain our data elements
    gluster_peers[peer] = {}

    gluster_peers[peer]['uuid'] = peer_xml.elements['uuid'].text.to_s
    gluster_peers[peer]['connected'] = peer_xml.elements['connected'].text.to_i
    gluster_peers[peer]['state'] = peer_xml.elements['state'].text.to_i
    gluster_peers[peer]['status'] = peer_xml.elements['stateStr'].text.to_s
  end

  # Collecting all hostnames of peers
  REXML::XPath.match(peer_status_xml, '/cliOutput/peerStatus/peer/hostnames/hostname').each do |hn|
    peer_list_ar.append(hn.to_a)
  end

  # Extract and format the data needed for the legacy peer facts.
  peer_count = gluster_peers.size
  peer_list = peer_list_ar.join(',')

  # Get our volume information from gluster volume info
  volume_info_xml = REXML::Document.new(Facter::Util::Resolution.exec("#{binary} volume info --xml"))
  REXML::XPath.match(volume_info_xml, '/cliOutput/volInfo/volumes/volume').each do |volume_xml|
    volume = volume_xml.elements['name'].text.to_s

    # Create hash entry for each volume in a structured fact.
    gluster_volumes[volume] = {}

    vol_status = volume_xml.elements['statusStr'].text.to_s
    gluster_volumes[volume]['status'] = vol_status

    # Define gluster_volumes[volume]['bricks'] as an array so we can .push() to it.
    gluster_volumes[volume]['bricks'] = []

    REXML::XPath.match(volume_xml, 'bricks/brick').each do |brick_xml|
      # We need to loop over the bricks so that we can change the text from :REXML::Text. to String
      brick_name = brick_xml.elements['name'].text.to_s
      gluster_volumes[volume]['bricks'].push(brick_name)
    end

    options = REXML::XPath.match(volume_xml, 'options/option').map { |option| "#{option.elements['name'].text}: #{option.elements['value'].text}" }
    if options
      volume_options[volume] = options
      gluster_volumes[volume]['features'] = {}
      gluster_volumes[volume]['options'] = {}
      # Convert options into key: value pairs for easy retrieval if needed.
      options.each do |option|
        option_name, set_value = option.split(': ', 2)

        if option_name =~ %r{^features\.}
          gluster_volumes[volume]['features'][option_name] = set_value
        else
          gluster_volumes[volume]['options'][option_name] = set_value
        end
      end
    end

    next unless vol_status == 'Started'

    volume_status_xml = REXML::Document.new(Facter::Util::Resolution.exec("#{binary} volume status #{volume} --xml"))
    volume_ports[volume] = REXML::XPath.match(volume_status_xml, "/cliOutput/volStatus/volumes/volume/node[starts-with(hostname/text(), '#{Facter.value('hostname')}')]/port/text()")

    # Define gluster_volumes[volume]['ports'] as an array so we can .push() to it.
    gluster_volumes[volume]['ports'] = []

    volume_ports[volume].each do |port|
      # port is of type: :REXML::Text.  Convert it to String and then Integer
      port_number = port.to_s.to_i
      gluster_volumes[volume]['ports'].push(port_number)
    end
  end

  # Export our facts
  Facter.add(:gluster_peer_count) do
    setcode do
      peer_count
    end
  end

  Facter.add(:gluster_peer_list) do
    setcode do
      peer_list
    end
  end

  # Create a new structured facts containing all peer and volume info.
  Facter.add(:gluster_peers) do
    setcode do
      gluster_peers
    end
  end

  Facter.add(:gluster_volumes) do
    setcode do
      gluster_volumes
    end
  end

  unless gluster_volumes.empty?
    Facter.add(:gluster_volume_list) do
      setcode do
        gluster_volumes.keys.join(',')
      end
    end
    gluster_volumes.each_key do |volume|
      Facter.add("gluster_volume_#{volume}_bricks".to_sym) do
        setcode do
          gluster_volumes[volume]['bricks'].join(',')
        end
      end
    end
    volume_options&.each do |vol, opts|
      # Create flat facts for each volume
      Facter.add("gluster_volume_#{vol}_options".to_sym) do
        setcode do
          opts.join(',')
        end
      end
    end
    volume_ports&.each do |vol, ports|
      Facter.add("gluster_volume_#{vol}_ports".to_sym) do
        setcode do
          ports.join(',')
        end
      end
    end
  end
end
