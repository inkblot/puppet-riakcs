# ex: syntax=puppet si ts=4 sw=4 et

class riakcs::params {
	$package_name        = 'riak-cs'
	$version             = latest
    $service_name        = 'riak-cs'
    $cs_ipaddress        = '127.0.0.1'
    $riak_ipaddress      = '127.0.0.1'
    $stanchion_ipaddress = '127.0.0.1'
    $vm_node_name        = 'riak-cs'
    $vm_ipaddress        = '127.0.0.1'
    $admin_email         = 'foobar@example.com'
    $admin_key           = ''
    $admin_secret        = ''
    $create_admin        = false
}
