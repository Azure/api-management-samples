# Setting up Secure VNET injection with API Management with Forced Tunneling

Setup includes API Management deployment with Azure Firewall to restrict all outbound traffic.
The Virtual Network is configured to Forced Tunnel all traffic to the Azure Firewall with no requirement for Service Endpoints.

The setup also includes calling into an API POST /outboundNetworkDependencyEndpoints which lists all the FQDN dependencies and sets up the Route Table. 

The setup involves setting up
- Azure Route Table
- Network Security Group
- Azure Firewall
- API Management