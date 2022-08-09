resource "oci_core_instance" "instance-master" {
  count = var.master_count
  agent_config {
    are_all_plugins_disabled = "false"
    is_management_disabled   = "false"
    is_monitoring_disabled   = "false"
    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Block Volume Management"
    }
  }
  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }
  availability_domain = data.oci_identity_availability_domain.oVBc-EU-FRANKFURT-1-AD-2.name
  compartment_id      = var.compartment_ocid
  display_name        = format("instance-master%02d", count.index + 1)
  fault_domain        = "FAULT-DOMAIN-1"
  instance_options {
    are_legacy_imds_endpoints_disabled = "false"
  }
  create_vnic_details {
    private_ip       = format("10.0.1.%d", count.index + 1)
    assign_public_ip = var.public_ip_enabled
    subnet_id        = oci_core_subnet.Public_subnet.id
  }
  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    is_consistent_volume_naming_enabled = "true"
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
  }
  metadata = {
    "ssh_authorized_keys" = file(var.id_rsa_pub)
  }
  shape = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = "8"
    ocpus         = "2"
  }
  source_details {
    boot_volume_size_in_gbs = "50"
    boot_volume_vpus_per_gb = "10"
    source_id               = var.instance-ARM_source_image_id
    source_type             = "image"
  }
  state = "RUNNING"
}

resource "oci_core_instance" "instance-node" {
  count = var.node_count
  agent_config {
    are_all_plugins_disabled = "false"
    is_management_disabled   = "false"
    is_monitoring_disabled   = "false"
    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Block Volume Management"
    }
  }
  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }

  availability_domain = data.oci_identity_availability_domain.oVBc-EU-FRANKFURT-1-AD-2.name
  compartment_id      = var.compartment_ocid
  display_name        = format("instance-node%02d", count.index + 1)
  fault_domain        = "FAULT-DOMAIN-1"
  instance_options {
    are_legacy_imds_endpoints_disabled = "false"
  }
  create_vnic_details {
    private_ip       = format("10.0.2.%d", count.index + 1)
    assign_public_ip = var.public_ip_enabled
    subnet_id        = oci_core_subnet.Public_subnet.id
  }
  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    is_consistent_volume_naming_enabled = "true"
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
  }
  metadata = {
    "ssh_authorized_keys" = file(var.id_rsa_pub)
  }
  shape = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = "8"
    ocpus         = "1"
  }
  source_details {
    boot_volume_size_in_gbs = "50"
    boot_volume_vpus_per_gb = "10"
    source_id               = var.instance-ARM_source_image_id
    source_type             = "image"
  }
  state = "RUNNING"
}

resource "oci_core_internet_gateway" "MainIGW" {
  compartment_id = var.compartment_ocid
  display_name   = "MainIGW"
  enabled        = "true"
  vcn_id         = oci_core_vcn.MainVCN.id
}

resource "oci_core_subnet" "Public_subnet" {

  cidr_block                 = "10.0.0.0/17"
  compartment_id             = var.compartment_ocid
  display_name               = "Public_subnet"
  dns_label                  = "publicsubnet"
  prohibit_internet_ingress  = "false"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_vcn.MainVCN.default_route_table_id
  security_list_ids = [
    oci_core_vcn.MainVCN.default_security_list_id,
  ]
  vcn_id = oci_core_vcn.MainVCN.id
}

resource "oci_core_vcn" "MainVCN" {

  cidr_blocks = [
    "10.0.0.0/16",
  ]
  compartment_id = var.compartment_ocid
  display_name   = "MainVCN"
  dns_label      = "mainvcn"
}

resource "oci_core_default_dhcp_options" "Default-DHCP-Options-for-MainVCN" {
  compartment_id             = var.compartment_ocid
  display_name               = "Default DHCP Options for MainVCN"
  domain_name_type           = "CUSTOM_DOMAIN"
  manage_default_resource_id = oci_core_vcn.MainVCN.default_dhcp_options_id
  options {
    server_type = "VcnLocalPlusInternet"
    type        = "DomainNameServer"
  }
  options {
    search_domain_names = [
      "publicsubnet.mainvcn.oraclevcn.com",
    ]
    type = "SearchDomain"
  }
}

resource "oci_core_default_route_table" "Route-Table-for-MainVCN" {
  compartment_id             = var.compartment_ocid
  display_name               = "Route Table for MainVCN"
  manage_default_resource_id = oci_core_vcn.MainVCN.default_route_table_id
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.MainIGW.id
  }
}

resource "oci_core_default_security_list" "Security-List-for-MainVCN" {
  compartment_id = var.compartment_ocid
  display_name   = "Security List for MainVCN"
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  ingress_security_rules {
    icmp_options {
      code = "0"
      type = "8"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "https"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    description = "http"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "80"
      min = "80"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    description = "kube"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "4443"
      min = "4443"
    }
  }
  ingress_security_rules {
    description = "kube"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    description = "kube"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "2380"
      min = "2379"
    }
  }
  ingress_security_rules {
    description = "kube"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "32767"
      min = "30000"
    }
  }
  ingress_security_rules {
    description = "kube"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "10260"
      min = "10250"
    }
  }
  ingress_security_rules {
    description = "kube"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "8443"
      min = "8443"
    }
  }
  ingress_security_rules {
    description = "https"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "8081"
      min = "8080"
    }
  }
  manage_default_resource_id = oci_core_vcn.MainVCN.default_security_list_id
}