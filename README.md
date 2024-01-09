# 🚀 Azure VM with OpenVPN Setup Bicep Template

This Bicep template automates the deployment of an Azure Virtual Machine (VM) with an OpenVPN server. The template uses a custom script extension to execute the `openvpn-setup.sh` script, which configures both the OpenVPN server and client on the VM.
## 🌟 Prerequisites

Before deploying the Bicep template, make sure you have:

- An Azure subscription
- The Azure CLI wand
- Git for cloning the repository

## ✨ Deployment Steps

1. **Clone the Repository:**

    ```bash
    git clone https://github.com/Selmouni-Abdelilah/openvpn.git
    cd openvpn
    ```

2. **Edit Parameters:**

    Open the `script.bicep` file and wield your wizardry on parameters like `adminUsername`, `adminPassword`, and more.

3. **Invoke the Bicep Incantation:**

    Run the following command to deploy the Bicep template:

    ```bash
    az deployment group create --resource-group <your-resource-group> --template-file script.bicep
    ```

    Replace `<your-resource-group>` with the name of your Azure resource group.

4. **Access the OpenVPN Server:**

    After deployment, get the VM's public IP address and connect using SSH or Remote Desktop.

5. **Verify OpenVPN Setup:**

    Access the VM and verify the OpenVPN server setup. Check OpenVPN logs and configurations.

## 🧙‍♂️ Custom Script Enchantment

This script is executed during VM provisioning. You can customize it according to your specific OpenVPN configuration requirements.

## 📜 Notes of Wisdom

- This template uses a basic OpenVPN setup. Review and modify configurations for your security needs.

- Consider integrating Azure Key Vault for secure storage of certificates and secrets in production.

## 📜 Script Explanation

The `openvpn-setup.sh` script does the following:

- Installs OpenVPN, Easy-RSA, iptables, and traceroute.
- Configures Easy-RSA files for OpenVPN.
- Generates server and client key/certificate pairs.
- Sets up OpenVPN server configurations.
- Enables IP forwarding and sets up NAT for VPN traffic.
- Restarts and enables the OpenVPN service.

Finally, it outputs the OpenVPN client configuration (`client.ovpn`) for easy client setup.

#### Feel free to contribute or customize this template based on your specific requirements. ✨
