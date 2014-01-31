# ex: syntax=puppet si ts=4 sw=4 et

class riakcs (
    $package_name        = $::riakcs::params::package_name,
    $version             = $::riakcs::params::version,
    $service_name        = $::riakcs::params::service_name,
    $cs_ipaddress        = $::riakcs::params::cs_ipaddress,
    $riak_ipaddress      = $::riakcs::params::riak_ipaddress,
    $stanchion_ipaddress = $::riakcs::params::stanchion_ipaddress,
    $vm_node_name        = $::riakcs::params::vm_node_name,
    $vm_ipaddress        = $::riakcs::params::vm_ipaddress,
    $admin_email         = $::riakcs::params::admin_email,
    $admin_key           = $::riakcs::params::admin_key,
    $admin_secret        = $::riakcs::params::admin_secret,
    $create_admin        = $::riakcs::params::create_admin,
) inherits riakcs::params {
    # Precedence:
    # The first puppetting of the first riakcs node in a cluster will create 
    # the admin user and capture the credentials in facts.  This *must* be the
    # stanchion node.  The first puppetting of subsequent nodes in the cluster
    # will fail unless either:
    # 1: The hard-coded facts on the first node have been copied to the
    #    subsequent nodes
    # 2: The fact values have been assigned to the admin_key and admin_secret
    #    parameters of this class.
    if $::riakcs_admin_key != '' and $::riakcs_admin_secret != '' {
        $_admin_key = $::riakcs_admin_key
        $_admin_secret = $::riakcs_admin_secret
    } elsif $admin_key != '' and $admin_secret != '' {
        $_admin_key = $admin_key
        $_admin_secret = $admin_secret
    } else {
        $_admin_key = 'admin-key'
        $_admin_secret = 'admin-secret'
    }

    # The default value for the admin_key means we're without an admin user
    $anonymous_user_creation = $_admin_key ? {
        'admin-key' => 'true',
        default => 'false',
    }

    File {
        owner   => 'riakcs',
        group   => 'riak',
        mode    => '0644',
    }

    package { 'riak-cs':
        name    => $package_name,
        ensure  => $version,
        require => Class['riak::repo'],
        before  => Service['riak'],
    }

    user { 'riakcs':
        ensure  => present,
        gid     => 'riak',
        require => Package['riak', 'riak-cs'],
    }

    file { '/etc/riak-cs/app.config':
        ensure  => present,
        content => template('riakcs/app.config.erb'),
        require => Package['riak-cs'],
        notify  => Service['riak-cs'],
    }

    file { '/etc/riak-cs/vm.args':
        ensure  => present,
        content => template('riakcs/vm.args.erb'),
        require => Package['riak-cs'],
        notify  => Service['riak-cs'],
    }

    service { 'riak-cs':
        name    => $service_name,
        ensure  => running,
        require => Service['riak'],
    }

    if $_admin_key == 'admin-key' {
        if $create_admin {
            class { 'riakcs::create_admin':
                admin_email         => $admin_email,
                cs_ipaddress        => $cs_ipaddress,
                stanchion_ipaddress => $stanchion_ipaddress,
            }
        } else {
            fail("No admin key and admin secret. Get these values from the stanchion node's riakcs_admin_key and riakcs_admin_secret facts and use them to set this class's admin_key and admin_secret parameters")
        }
    }
}
