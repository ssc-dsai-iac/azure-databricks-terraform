# ---------------------------------------------------------------------------------------------------------------------
# Creating Azure Databricks workspace
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_databricks_workspace" "this" {
  name                                  = var.databricks_workspace_name
  resource_group_name                   = var.resource_group_name
  location                              = var.location
  sku                                   = var.sku
  load_balancer_backend_address_pool_id = var.secure_cluster_connectivity ? azurerm_lb_backend_address_pool.this.id : null
  managed_resource_group_name           = var.secure_cluster_connectivity ? var.databricks_workspace_name : "${var.name}-rg"

  dynamic "custom_parameters" {
    count                                                = var.secure_cluster_connectivty ? 1 : 0
    virtual_network_id                                   = azurerm_virtual_network.this.id
    private_subnet_name                                  = azurerm_subnet.private.name
    public_subnet_name                                   = azurerm_subnet.public.name
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Creating Azure Databricks Cluster
# ---------------------------------------------------------------------------------------------------------------------

data "databricks_node_type" "smallest" {
  depends_on = [azurerm_databricks_workspace.this]
  local_disk = true
}

data "databricks_spark_version" "latest_lts" {
  depends_on        = [azurerm_databricks_workspace.this]
  long_term_support = true
}

resource "databricks_cluster" "main" {
  cluster_name            = var.cluster_name
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  autoscale {
    min_workers = 1
    max_workers = 2
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Create Access policy to Key Vault
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_secret_scope" "kv" {
  depends_on = [
    azurerm_databricks_workspace.this,
    databricks_cluster.main
  ]
  name = "keyvault-managed"

  keyvault_metadata {
    resource_id = var.key_vault_id
    dns_name    = var.key_vault_uri
  }
}
