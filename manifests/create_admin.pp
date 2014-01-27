# ex: syntax=puppet si ts=4 sw=4 et

class riakcs::create_admin (
    $admin_email,
    $cs_ipaddress,
    $stanchion_ipaddress,
) {

    file { '/usr/local/riak-cs':
        ensure => directory,
        owner  => 'riakcs',
        group  => 'riak',
        mode   => '0755',
    }

    file { '/usr/local/riak-cs/create-admin-user':
        ensure => present,
        owner  => 'riakcs',
        group  => 'riak',
        mode   => '0755',
        source => 'puppet:///modules/riakcs/create-admin-user',
    }

    exec { 'riakcs create admin':
        command   => "/usr/local/riak-cs/create-admin-user '${admin_email}' ${cs_ipaddress} ${stanchion_ipaddress}",
        user      => 'root',
        logoutput => on_failure,
        require   => [ Service['riak-cs'], File['/usr/local/riak-cs/create-admin-user'] ],
    }

    exec { 'riakcs restart':
        command   => '/usr/sbin/service riak-cs restart',
        user      => 'root',
        subscribe => Exec['riakcs create admin'],
    }
}
