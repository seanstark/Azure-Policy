# Overview
Reference the below table on these custome policies

# Policy Lists
| Poliy Name | Use Case | Scope | 
| ---------- | -------- | ----- |
| assign-dcr-with-tag-filtering.json | Assigns a data collection rule scoped to virtualmachines with tags | scoped to virtualmachines with tags |
| audit-networkwatcher-extension-virtual-machines.json | Audits the existance of the NetworkWatcher extension| Microsoft.Compute/virtualMachines |
| configure-dcr-linux-arc-machines.json | Assigns a data collection rule to all linux arc machines | linux arc machines |
| configure-dcr-linux-virtual-machines.json | Assigns a data collection rule to all linux virtual machines | linux machines |
| configure-dcr-linux-vmss.json | Assigns a data collection rule to all linux vmss machines | linux vmss |
| configure-dcr-windows-arc-machines.json | Assigns a data collection rule to all windows arc machines | windows arc machines |
| configure-dcr-windows-virtual-machines.json | Assigns a data collection rule to all windows virtual machines  | windows virtual machines |
| configure-dcr-windows-vmss.json | Assigns a data collection rule to all windows vmss machines | windows vmss machines |
| configure-linux-vms-with-a-azure-monitor-agent-version-and-upgrade-policy.json | Deploys a specific version of the Azure Monitor Agent with auto-upgrade disabled | linux virtual machines |
| configure-linux-arc-with-a-azure-monitor-agent-version-and-upgrade-policy.json | Deploys a specific version of the Azure Monitor Agent with auto-upgrade disabled | linux arc machines |
| configure-networkwatcher-extension-linux-virtual-machines.json | Deploys the networkwatcher extension for linux vritual machines | linux vritual machines |
| configure-networkwatcher-extension-windows-virtual-machines.json | Deploys the networkwatcher extension for windows vritual machines | windows vritual machines |
| enable-managed-identity-vms.json | Enables a system managemed identity on virtual and vmss machines | virtual and vmss machines; all operating systems |
| run-deploymentscript-with-ama.json | Deploys the Linux Azure Monitor Agent to machines with a tag and runs a deployment script after installation | machines with a tag |
| deny-sub-activity-log-from-deletion.json | Prevents Deletion of a Subscription Activity Log Diagnostic Settings based on name |
