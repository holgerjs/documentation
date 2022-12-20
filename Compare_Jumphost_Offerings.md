# Jumphost Comparison

Jumphosts are useful for securely accessing hosts on private networks or individually secured network segments - however, AWS and Azure are offering such services as platform services (PaaS) where the responsibility for managing the underlying infrastructure remains with the Cloud vendor, allowing customers to further reduce their IaaS footprint. This document includes _some_ details about (and an attempted comparison between) the different offerings. Note that this is not an exhaustive description, there may be errors and/or some details may be missing or have changed in the meantime. Review the official documentation for full and up-to-date details - some links are provided in the References section.

## Offerings

| # | Hyperscaler | Offering |
|---| --- | --- |
| 1 | GCP | GCP does not seem to have an offering for a managed Bastion Server. Steps for creating a Bastion host for the Google Cloud Platform are outlined [here](https://cloud.google.com/solutions/connecting-securely#bastion)
| 2 | AWS | [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
| 3 | Azure | [Azure Bastion](https://learn.microsoft.com/en-us/azure/bastion/bastion-overview)

## AWS Systems Manager Session Manager

AWS Session Manager is part of the [AWS Systems Manager](https://aws.amazon.com/systems-manager/) eco system, which is an end-to-end management solution for hybrid cloud environmens. Session Manager is part of its Node Management features.

> AWS Systems Manager provides a browser-based interactive shell, CLI and browser based remote desktop access for managing instances on your cloud, or on-premises and edge devices, without the need to open inbound ports, manage Secure Shell (SSH) keys, or use bastion hosts. Administrators can grant and revoke access to instances through a central location by using AWS Identity and Access Management (IAM) policies. This allows you to control which users can access each instance, including the option to provide non-root access to specified users. Once access is provided, you can audit which user accessed an instance and log each command to Amazon Simple Storage Service (S3) or Amazon CloudWatch Logs using AWS CloudTrail.
<br>&mdash; <cite>Amazon Web Services </cite>[5]

### Requirements

For full details, please see the [Session Manager Prerequisites](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-prerequisites.html) outlined in the AWS documentation.

- Session Manager supports all operating system versions that are [supported by AWS Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/prereqs-operating-systems.html).
- Requires an agent to be deployed on the managed nodes (AWS Systems Manager SSM Agent version 2.3.68.0 or later; for encrypted sessions 2.3.539.0 or later)
- A session user with root / Administrator permissions is automatically created (`ssm-user`).
- HTTPS outbound traffic to specific AWS endpoints is required for all managed nodes (unless AWS PrivateLink is used).
- When using Session Manager to connect to non-EC2 nodes, the [advanced-instances tier](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managed-instances-tiers.html) must be activated. This incurs additional charges.

### Session Access

"AWS Systems Manager Session Manager allows you to centrally grant and revoke user access to managed nodes." [9] AWS IAM policies are used to control access to the managed nodes and control access over the Session Manager API. AWS provides a set of [sample policies for Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-restrict-access-examples.html).

### Session Manager Features

AWS Systems Manager Session Manager is shipped with the following [configurable session preferences](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-configure-preferences.html):

- Specify session timeouts between 1 and 60 minutes of inactivity. The AWS documentation suggests that a session timeout of 15 minutes as a maximum is recommended by some professional computing security agencies. [12]
- Specify maximum session duration between 1 and 1,440 minutes.
- Configurable shell profiles.
- Run-as support for Linux and macOS managed nodes (and not use the default, system-generated `ssm-user` credentials).
- Encryption of session data between managed nodes and the local machines of users. This requires AWS KMS and is in addition to TLS 1.2.
- Restrict access to commands in a session. Through AWS Systems Manager Documents, it is possible to restrict which commands a user can run on which managed nodes.
- AWS PrivateLink is supported by AWS Session Manager. [14]
- Session Manager can act as a tunnel for SSH and RDP connections (through AWS CLI).
- Sessions can be audited using AWS CloudTrail. [15]
- Session data can be streamed/logged to CloudWatch Logs or logged directly into an S3 bucket. [16]

Alternatively, in order to establish RDP connections directly from the browser, [AWS Systems Manager Fleet Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/fleet-rdp.html) is required, however, there are limitations to be aware of - such as specific timeouts and a maximum of 25 concurrent RDP connections per region and account [17].

### Pricing

The [AWS Systems Manager Pricing documentation](https://aws.amazon.com/systems-manager/pricing/) does not indicate additional charges for accessing Amazon EC2 instances through AWS Systems Manager Session Manager. However, [network egress traffic](https://aws.amazon.com/ec2/pricing/on-demand/#Data_Transfer) will incur costs.

Furthermore, when Session Manager is used in hybrid scenarios to access on-premises VMs (or, generally, non-EC2 instances), then the [advanced on-premises instance tier is required, which will incur additional costs](https://aws.amazon.com/systems-manager/pricing/#On-Premises_Instance_Management) as well.

## Azure Bastion

> Azure Bastion is a service you deploy that lets you connect to a virtual machine using your browser and the Azure portal, or via the native SSH or RDP client already installed on your local computer. The Azure Bastion service is a fully platform-managed PaaS service that you provision inside your virtual network. It provides secure and seamless RDP/SSH connectivity to your virtual machines directly from the Azure portal over TLS. When you connect via Azure Bastion, your virtual machines don't need a public IP address, agent, or special client software.
<br>&mdash; <cite>Microsoft </cite>[3]

### Requirements

- Azure Bastion requires a dedicated /26 subnet.
- Destination VMs need to allow the following inbound ports from the Azure Bastion Subnet:
    - 3389 for Windows VMs
    - 22 for Linux VMs
- Web browsers must support HTML 5.

### Bastion Access

Azure Bastion lives in its own, dedicated subnet. There is no NSG required on the Bastion subnet, however, subnets that include workload VMs that should be accessed through Azure Bastion need to have incoming RDP or SSH traffic _from_ th Azure Bastion Subnet allowed.

From a permissions point of view, there are two levels involved. Azure RBAC and the operating system.

#### Azure RBAC

Users who use Azure Bastion to access a VM need to hold or (if [Azure PIM](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-configure) is used) be eligible for the [following roles](https://learn.microsoft.com/en-us/azure/bastion/bastion-faq#roles):

- Reader role on the virtual machine.
- Reader role on the NIC with private IP of the virtual machine.
- Reader role on the Azure Bastion resource.
- Reader Role on the virtual network of the target virtual machine (if the Bastion deployment is in a peered virtual network).  

#### Workload

On OS-level, users need to be in the Remote Desktop Users group in order to be able to login to the VM.

### Features

Azure Bastion comes with [two different SKUs](https://learn.microsoft.com/en-us/azure/bastion/bastion-overview#sku). 

- RDP and SSH through the Azure portal over TLS
- Kerberos authentication
- VM audio output
- Shareable link (only Standard SKU)
- Connect to VMs using a native client (only Standard SKU)
- Host scaling (only Standard SKU)
- Upload or download files (only Standard SKU)
- Disable copy/paste (for web-based clients) (only Standard SKU)
- 2 Instances (Basic SKU); [up to 50 instances](https://learn.microsoft.com/en-us/azure/bastion/bastion-overview#host-scaling) (Standard SKU) 

### Pricing

Charges are based on a combination of the componets below. See the [Azure Bastion Pricing documentation](https://azure.microsoft.com/en-gb/pricing/details/azure-bastion/) for more details. 

-  Hourly pricing based on SKU and amount of instances.
-  Outbound data transfer

## Comparison

| Criteria  	    | Jump Host  	                                            | AWS Systems Manager Session Manager | Azure Bastion  	|
|---                |---	                                                    |---	                              | ---             |
| Service Model     | IaaS	                                                    | PaaS                                | PaaS            |
| Exposure       	| Internal or External                                      | External                | External          |
| Pricing           | Charges apply for Compute, Storage and Network Traffic    | Network egress traffic is charged as well as access to non-EC2 nodes (advanced access tiers).           | Charged on an hourly basis per instance and for network traffic    	            |
| Can be accessed through Private Endpoints? | not required | Yes (AWS PrivateLink) | No |
| Subnet Requirements               | Minimum /29              |None (unless AWS PrivateLink is used)                          | Minimum /26   |
| Network Access Requirements | Allow Inbound RDP/SSH traffic from client network | None | Allow Inbound RDP/SSH traffic from Azure Bastion Subnet |
| UDR Support                       | Yes               | n/a                                    |  No            |
| Agent required                    | No                | Yes                                 | No |
| Authentication Requirements | Azure RBAC: <ul><li>None</li></ul>VM:<ul><li>Local or Domain User Credentials which are member of the Remote Desktop Users Group (for Windows OS)</li></ul> | AWS IAM: <ul><li>Session Manager permissions</li> <li>Permissions to connect to the appropriate instances.</li>  </li></ul>VM:<ul><li>Local or Domain User Credentials which are member of the Remote Desktop Users Group (for Windows OS)</li></ul>       |Azure RBAC: <ul><li>Reader role on the virtual machine.</li> <li>Reader role on the NIC with private IP of the virtual machine.</li> <li>Reader role on the Azure Bastion resource.</li> <li>Reader Role on the virtual network of the target virtual machine (if the Bastion deployment is in a peered virtual network).</li></ul>VM:<ul><li>Local or Domain User Credentials which are member of the Remote Desktop Users Group (for Windows OS)</li></ul> |
| Connection Limits | 2 RDP Connections (unless Terminal Services are deployed and RDS licenses are used)   | None |  Each [instance](https://learn.microsoft.com/en-us/azure/bastion/configuration-settings#instance) can support 25 concurrent RDP connections and 50 concurrent SSH connections for medium workloads |
| Logging | OS-level Logging | Session Logs & Session Activity (except for Port Forwarding/RDP) | Activity Logs |
| Usage | SSH / RDP Cients | <ul><li>Browser-based SSH</li><li>RDP and SSH Clients (through Port forwarding) </li></ul> | <ul><li>Primarily browser-based (HTML5)</li><li>Using clients is possible with the Standard SKU</li></ul> |

## References

| # | Title | Link | Accessed On |
|---| --- | --- | --- |
| 1 | Compute Engine - Securely connecting to VM instances - Bastion Hosts | https://cloud.google.com/solutions/connecting-securely#bastion | 2022-12-12
| 2 | User Guide - AWS Systems Manager Session Manager | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html | 2022-12-12
| 3 | Overview - Azure Bastion | https://learn.microsoft.com/en-us/azure/bastion/bastion-overview | 2022-12-12
| 4 | AWS Systems Manager | https://aws.amazon.com/systems-manager/ | 2022-12-12
| 5 | AWS Systems Manager Features | https://aws.amazon.com/systems-manager/features/#Session_Manager | 2022-12-12
| 6 | AWS Systems Manager - Supported Operating Systems | https://docs.aws.amazon.com/systems-manager/latest/userguide/prereqs-operating-systems.html | 2022-12-12
| 7 | Session Manager Prerequisites | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-prerequisites.html | 2022-12-12
| 8 | AWS Systems Manager - Configuring instance tiers | https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managed-instances-tiers.html | 2022-12-12
| 9 | Session Manager - Control user session access to managed nodes | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-restrict-access.html | 2022-12-12
| 10 | Session Manager - Additional sample IAM policies for Session Manager | https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-restrict-access-examples.html | 2022-12-12
| 11 | Session Manager - Configure session preferences | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-configure-preferences.html | 2022-12-12
| 12 | Session Manager - Specify an idle session timeout value | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-preferences-timeout.html | 2022-12-12
| 13 | Session Manager - Turn on KMS key encryption of session data (console) | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-preferences-enable-encryption.html | 2022-12-12
| 14 | Session Manager - Use AWS PrivateLink to set up a VPC endpoint for Session Manager | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-privatelink.html | 2022-12-12
| 15 | Session Manager - Auditing session activity | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-auditing.html | 2022-12-12
| 16 | Session Manager - Logging session activity | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-logging.html | 2022-12-12
| 17 | Fleet Manager - Connect using Remote Desktop | https://docs.aws.amazon.com/systems-manager/latest/userguide/fleet-rdp.html | 2022-12-12
| 18 | AWS Systems Manager - Pricing | https://aws.amazon.com/systems-manager/pricing/ | 2022-12-12
| 19 | Amazon EC2 On-Demand Pricing - Data Transfer | https://aws.amazon.com/ec2/pricing/on-demand/#Data_Transfer | 2022-12-12
| 20 | AWS Systems Manager - On-Premises Instance Management Pricing | https://aws.amazon.com/systems-manager/pricing/#On-Premises_Instance_Management | 2022-12-12
| 21 | Azure Bastion SKUs | https://learn.microsoft.com/en-us/azure/bastion/bastion-overview#sku | 2022-12-12
| 22 | Azure Bastion Pricing | https://azure.microsoft.com/en-gb/pricing/details/azure-bastion/ | 2022-12-12
| 23 | What is Azure AD Privileged Identity Management? | https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-configure | 2022-12-12
| 24 | Bastion FAQ | https://learn.microsoft.com/en-us/azure/bastion/bastion-faq | 2022-12-12
| 25 | Bastion Host Scaling | https://learn.microsoft.com/en-us/azure/bastion/bastion-overview#host-scaling | 2022-12-12
| 26 | YouTube: Securely Access Windows Instances Using RDP and AWS Systems Manager Session Manager | https://www.youtube.com/watch?v=nt6NTWQ-h6o | 2022-12-13
