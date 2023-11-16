# Front Door

### CAUTION

- Due to dependency issues, an error may occur when creating a Front Door Route. In this case, run `terraform apply` again and it will succeed.

    ```bash
    │ Error: creating Front Door Route: (Route Name "fdr-aozoragpt-prod-jpeast-001" / Afd Endpoint Name "fde-aozoragpt-prod-jpeast" / Profile Name "afd-aozoragpt-prod-jpeast" / Resource Group "rg-aozoragpt-prod"): cdn.RoutesClient#Create: Failure sending request: StatusCode=400 -- Original Error: Code="BadRequest" Message="Please make sure that the originGroup is created successfully and at least one enabled origin is created under the origin group."
    │
    │   with module.frontdoor.azurerm_cdn_frontdoor_route.main,
    │   on ../../../modules/frontdoor/main.tf line 90, in resource "azurerm_cdn_frontdoor_route" "main":
    │   90: resource "azurerm_cdn_frontdoor_route" "main" {
    │
    ```

- Currently, creating a custom domain must be done manually as it does not work with DNS. We have identified the following issues. The following issues have been identified, which are usually reflected automatically from the Front Door settings in Azure Portal.
  - TXT records for domain validation are not created in Azure DNS
  - Alias records are not created in DNS

- Container app connections are made via private links. Therefore, the target private endpoint connection must be selected from the private link service and the connection status must be set to approved. This must be done manually. Failure to do so will cause the front door to fail to connect to the container app.
