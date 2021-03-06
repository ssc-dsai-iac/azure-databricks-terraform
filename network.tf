# ---------------------------------------------------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_network" "this" {
  count = var.secure_cluster_connectivty ? 1 : 0

  name                = "${var.databricks_workspace_name}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space = ["10.0.0.0/16"]
}

# ---------------------------------------------------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_subnet" "private" {
  count = var.secure_cluster_connectivty ? 1 : 0

  name = "${var.databricks_workspace_name}-snet"

  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.0.0/24"]

  delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet" "public" {
  count = var.secure_cluster_connectivty ? 1 : 0

  name                 = "${var.databricks_workspace_name}-pub-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Network Security Groups
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_security_group" "private" {
  count = var.secure_cluster_connectivty ? 1 : 0

  name                = "${var.databricks_workspace_name}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count = var.secure_cluster_connectivty ? 1 : 0

  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}


resource "azurerm_network_security_group" "public" {
  count = var.secure_cluster_connectivty ? 1 : 0

  name                = "${var.databricks_workspace_name}-pub-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_subnet_network_security_group_association" "public" {
  count = var.secure_cluster_connectivty ? 1 : 0

  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}



# ---------------------------------------------------------------------------------------------------------------------
# Load Balancer
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_public_ip" "this" {
  count = var.secure_cluster_connectivty ? 1 : 0

  name                = "${var.databricks_workspace_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_lb" "this" {
  count = var.secure_cluster_connectivty ? 1 : 0

  name                = "${var.databricks_workspace_name}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                 = "DatabricksPublicIPAddress"
    public_ip_address_id = azurerm_public_ip.this[0].id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  count = var.secure_cluster_connectivty ? 1 : 0

  name                = "${var.databricks_workspace_name}-bap"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.this[0].id
}
