# ---------------------------------------------------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "this" {
  name = format("vn-%s-%s-%s",
  local.naming.location[var.location], var.environment, var.project)

  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  address_space = ["10.0.0.0/16"]
}

# ---------------------------------------------------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_subnet" "private" {
  name = "${var.databricks_workspace_name}-snet"

  resource_group_name  = azurerm_resource_group.this.name
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
  name                 = "${var.databricks_workspace_name}-pub-snet"
  resource_group_name  = azurerm_resource_group.this.name
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
  name                = "${var.databricks_workspace_name}-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}


resource "azurerm_network_security_group" "public" {
  name                = "${var.databricks_workspace_name}-pub-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}



# ---------------------------------------------------------------------------------------------------------------------
# Load Balancer
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_public_ip" "this" {
  name                = "${var.databricks_workspace_name}-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "this" {
  name                = "${var.databricks_workspace_name}-lb"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  frontend_ip_configuration {
    name                 = "DatabricksPublicIPAddress"
    public_ip_address_id = azurerm_public_ip.this.id
  }
}
