# Azure VM Application Policies

## Overview
These policies will deploy [Azure VM Applications](https://learn.microsoft.com/azure/virtual-machines/vm-applications?) to Windows and Linux virtual machines + virtual machine scale sets

## Deployment Methods

The deployment methods are dictated by how you share your Azure Compute Galleries. 
Users, service principals, and managed identities all require read access to the vm applications you are planning on deploying. 
In order for the deployIfNotExists method to be effective you need to follow the below:

- The managed identity used by the remediation task requires read access to the Azure Compute Galleries where the application versions reside
- Users and service principals deploying or managing virtual machines requires read access to the Azure Compute Galleries where the application versions reside

There are three methods to [share images](https://learn.microsoft.com/azure/virtual-machines/share-gallery) in an Azure Compute Gallery, depending on who you want to share with:

| Sharing Method | People | Groups | Service Principal | All users in a specific subscription or tenant | Publicly with all users in Azure |
|---|---|---|---|---|---|
| RBAC  | Yes | Yes | Yes | No | No |
| Direct shared gallery | Yes | Yes | Yes | Yes | No |
| Community gallery | Yes | Yes | Yes | No | Yes |

### Using the RBAC Sharing Method
If you plan on using the RBAC sharing method you need to perform the following:
1. Assign the managed identity associated the with policy assignment the reader role to the Azure Compute Gallery where the application versions reside
2. Assign all users and service principals that deploy and manage virtual machines in scope of the policy assignment the reader role to the Azure Compute Gallery where the application versions reside

### Using the Direct sharing method
If you plan on using the Direct sharing method you do not need to take additional steps as the Azure Compute Gallery is already shared to all identities in the subscription or tenant
