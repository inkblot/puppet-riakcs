# ex: syntax=puppet si ts=4 sw=4 et

class riakcs (
    $package_name        = $::riakcs::params::package_name,
    $version             = $::riakcs::params::version,
    $service_name        = $::riakcs::params::service_name,
    $service_ensure      = $::riakcs::params::service_ensure,
    $cs_ipaddress        = $::riakcs::params::cs_ipaddress,
    $riak_ipaddress      = $::riakcs::params::riak_ipaddress,
    $stanchion_ipaddress = $::riakcs::params::stanchion_ipaddress,
    $vm_node_name        = $::riakcs::params::vm_node_name,
    $vm_ipaddress        = $::riakcs::params::vm_ipaddress,
    $admin_email         = $::riakcs::params::admin_email,
) inherits riakcs::params {
    $admin_key = $::riakcs_admin_key ? {
        '' => 'admin-key',
        default => $::riakcs_admin_key,
    }
    $admin_secret = $::riakcs_admin_secret ? {
        '' => 'admin-secret',
        default => $::riakcs_admin_secret,
    }
    $anonymous_user_creation = $admin_key ? {
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
        name   => $service_name,
        ensure => $service_ensure,
    }

    if $service_ensure == 'running' and $admin_key == 'admin-key' {
        class { 'riakcs::create_admin':
            admin_email         => $admin_email,
            cs_ipaddress        => $cs_ipaddress,
            stanchion_ipaddress => $stanchion_ipaddress,
        }
    }
}
