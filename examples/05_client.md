Gluster Client
==============

Included in this module is a gluster::client class. This is a helper class that installs just the Gluster client components. You can use this to ensure that your Gluster clients only ever get the client packages.

    node /app[1-3].local/ {
      class { gluster::client:
        repo    => true,
        version => '7.9',
      }
    }

You could also use this class in a simple defined type that manages Gluster mounts for your clients.

We use something like the following to wrap the combination of gluster::client and any number of mount points stored in Hiera:

```puppet
define gluster_mount (
  $options = undef,
) {
    if ! defined ( Class[::gluster::client] ) {
    include gluster::client
  }

  if ! defined ( File['/gluster'] ) {
    file { '/gluster':
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0775',
    }
  }

  if ! defined ( File["/gluster/${title}"] ) {
    file { "/gluster/${title}":
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => '0775',
      require => File['/gluster'],
    }
  }

  $gluster_mounts = hiera_hash('gluster_mounts')
  validate_hash( $gluster_mounts )

  $default_options = 'noatime,nodev,noexec,nosuid'
  $_options = join( $default_options, $options, ',')

  if ! defined ( Gluster::Mount["/gluster/${title}"] )
    and has_key( $gluster_mounts, $title ) {
    gluster::mount { "/gluster/${title}":
      ensure  => 'mounted',
      volume  => $gluster_mounts[$title],
      options => $_options,
      require => File["/gluster/${title}"],
    }
  }
}
```

The corresponding Hiera data structures look like this:

    gluster_mounts:
      admin: gluster1.local:/admin
      data: gluster1.local:/data

In other Puppet classes, we can then trivially ensure that a Gluster volume is defined and mounted:

    if ! defined( gluster_mount['admin'] ) {
      gluster_mount { 'admin': }
    }

All of the above could be accomplished with the base gluster class. The sole advantage to using gluster::client is to ensure that no server components are ever installed.
