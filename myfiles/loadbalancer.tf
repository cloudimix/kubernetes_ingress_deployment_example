resource "oci_load_balancer_load_balancer" "kubeLB" {
  compartment_id = var.compartment_ocid
  display_name   = "cluster_lb"
  ip_mode        = "IPV4"
  is_private     = "false"
  shape          = "flexible"
  shape_details {
    maximum_bandwidth_in_mbps = "10"
    minimum_bandwidth_in_mbps = "10"
  }
  subnet_ids = [
    oci_core_subnet.Public_subnet.id
  ]
}

resource "oci_load_balancer_backend_set" "backend_host" {
  health_checker {
    interval_ms         = "10000"
    port                = "443"
    protocol            = "TCP"
    response_body_regex = ""
    retries             = "3"
    return_code         = "200"
    timeout_in_millis   = "3000"
    url_path            = "/"
  }
  load_balancer_id = oci_load_balancer_load_balancer.kubeLB.id
  name             = "bs_lb_ver1"
  policy           = "ROUND_ROBIN"
}

resource "oci_load_balancer_backend" "node_443" {
  count            = var.node_count
  backendset_name  = oci_load_balancer_backend_set.backend_host.name
  backup           = "false"
  drain            = "false"
  ip_address       = format("10.0.2.%d", count.index + 1)
  load_balancer_id = oci_load_balancer_load_balancer.kubeLB.id
  offline          = "false"
  port             = "443"
  weight           = "1"
}

resource "oci_load_balancer_listener" "kubeLB_listener_lb_ver1" {
  connection_configuration {
    backend_tcp_proxy_protocol_version = "0"
    idle_timeout_in_seconds            = "60"
  }
  default_backend_set_name = oci_load_balancer_backend_set.backend_host.name
  load_balancer_id         = oci_load_balancer_load_balancer.kubeLB.id
  name                     = "listener_lb_ver1"
  port                     = "443"
  protocol                 = "TCP"
}
