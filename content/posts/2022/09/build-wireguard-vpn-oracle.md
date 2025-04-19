---
title: Build Your Own Free VPN with Oracle Cloud
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: http://res.cloudinary.com/ta1da-cloud/image/upload/v1663240383/realm/covers/Build%20Your%20Own%20Free%20VPN%20with%20Oracle%20Cloud.jpg
tags: ["Tutorial"]
description: In this tutorial, we will build and deploy our own VPN server using Wireguard to an Always Free Oracle Cloud instance hosted in any location of your choice.
patreon: true
publishDate: 2022-09-15
---

## Requirements

- A working debit/credit card. (You will not be charged, but it is a requirement nonetheless).
- Free time.
- A desire to learn.
- Probably patience.

### What is a VPN and why do you need one?

A VPN is a means of creating an encrypted tunnel that establishes a protected network when using public networks. My time in China taught me the importance of VPNs, even though they are useful for more than just spoofing one's location. VPNs give us some modicum of anonymity whilst surfing the internet, allowing us to hide our traffic from our ISPs and other nosey observers. This is especially important on public networks where we are vulnerable to exploitation by bad actors. While there are many VPN providers out there, they have their advantages and disadvantages. One of these disadvantages is the reason for this tutorial -- VPN providers could, in theory, see all your online traffic because it is passing through their systems. While most of them will say that they do not keep logs, we can spare ourselves the uncertainty by building a personal VPN. And, the best part is that it's free.

### Introduction

In this tutorial, we will build and deploy our own VPN server using Wireguard to an `Always Free` Oracle Cloud VM hosted in any location of your choice. According to their website,

> Wireguard is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography.

We'll use Wireguard because it is designed to be easy to set up, less resource intensive, and faster than competitors like OpenVPN.

### Creating an account on Oracle Cloud Infrastructure

- Navigate to [https://signup.cloud.oracle.com/](https://signup.cloud.oracle.com/)
- The first thing you will see are the terms for Oracle's Free Tier

  ![terms](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149672/realm/tutorials/oci-wg-imgs/free-tier-terms_slnt9k.png)

Oracle provides one of the most generous free tiers in the game, and because it's Always Free, instead of automatically upgrading if you go over your limit, they'll simply cut you off. The free tier includes access to **Compute** (which we will be using for this tutorial), **Object Storage**, **Autonomous Data Warehousing** and many more useful resources. The sign up process requires basic identification information such as your name, email, and address.

![Required Info](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149665/realm/tutorials/oci-wg-imgs/account-info_edti6e.png)

During this process we also pick a home region. According to Oracle, this is where all your data will be stored. It is permanent and cannot be changed later on a free account. This location will be the base location for your VPN so take this into consideration.

![Home Region](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149677/realm/tutorials/oci-wg-imgs/password-and-home-reg_zb66ub.png)

The last step is to input your credit card information. In my experience, Oracle will not charge you anything, however the card information is used to verify your identity (and probably ensure that the free trial is not abused).

![Payment Verification](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149676/realm/tutorials/oci-wg-imgs/payment-ver_vw7aly.png)

After confirming your email, you will be directed to the Oracle Cloud dashboard where you can access all the resources.

### Creating a Virtual Cloud Network (VCN)

- Our instance must be launched into a VCN and subnet. A subnet is a subdivision of the VCN.
- We use the navigation pane to navigate to Networking as shown above. Click on **Virtual Cloud Networks**

  ![](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149672/realm/tutorials/oci-wg-imgs/oci-navigation_hk4qcb.png)

- Our VCN will require network connectivity since we will be accessing it over the internet via the VM's public IP. Click on **Start VCN Wizard**.
- Select **Create VCN with Internet Connectivity** and then click **Start VCN Wizard**

  ![Start VCN Wizard](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149684/realm/tutorials/oci-wg-imgs/VCNs_hryejo.png)

- We select the option for a VCN with internet connectivity.

  ![VCN Config](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149681/realm/tutorials/oci-wg-imgs/vcn-config_tqt8dv.png)

- The VCN should be configured as follows (feel free to do it differently, of course).
- - **VCN Name** for your cloud network. Avoid using confidential information as this will be incorporated into all related resources that will be automatically created.
  - **Compartment** defaults to the current compartment
  - **VCN CIDR Block** enter a valid (Classless Inter Domain Routing) CIDR block for the VCN.

    - For the purpose of this tutorial, you don't need to understand any networking but, if you are curious, you can _check this out_ [add link to a relatively short networking tutorial].
    - Enter 10.0.0.0/16

  - **Public Subnet CIDR Block** enter a valid CIDR block that is within range e.g. 10.0.0.0/24
  - **Private Subnet CIDR Block**: enter a valid CIDR block that is within range e.g. 10.0.1.0/24 (must be different from the public subnet).
  - Accept all other defaults.
  - Click **Next**

- Review all the resources. The wizard will create multiple resources and set up security list rules and route tables to enable basic network access for the VCN.
- Click **Create** to create the components.
- After creation, click **View Virtual Cloud Network** to view your network.
- Your VCN will have the followeing resources and characteristics

  ![vcn characteristics image](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149682/realm/tutorials/oci-wg-imgs/vcn-char_grfcmm.png)

- Disclaimer

  ![disclaimer](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149682/realm/tutorials/oci-wg-imgs/vcn-disclaimer_ltimg8.png)

### Launching a Linux instance

- With our VCN set up, we can now create a Linux instance.
- Navigate to **Compute** in the navigation pane, then select **Instances**

  ![navigate to instance](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149672/realm/tutorials/oci-wg-imgs/oci-nav_aljilq.png)

- You can think of your instance as a computer running in the cloud. Unlike your personal computer, however, it runs on a server in a data center sharing hardware with many other instances that are isolated from each other.
- Click **Create instance**
- Name your instance, once again avoiding confidential information.
- Customize your image and shape.
- For this tutorial, we will use an ARM-based shape, VM.Standard.A1.Flex, running Ubuntu 22.04.

  ![OS options](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149671/realm/tutorials/oci-wg-imgs/instance-image-select_vomsdr.png)

- You're free to choose a different distribution, but some commands in this tutorial might not work in that case.

  ![image and shape](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149670/realm/tutorials/oci-wg-imgs/image-and-shape_mshpul.png)

- The next step is to configure the networking to allow the instance to connect to the internet and other requried resources.

  ![instance networking](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149671/realm/tutorials/oci-wg-imgs/instance-networking_fgnyll.png)

- For the primary network, select **Select existing VCN**

  - Select the VCN from the dropdown menu

- For the subnet, select **Select existing subnet** again

  - Select the **Public** Subnet from the dropdown menu

- Select **Assign a public IPv4 address** to create an IP address for the instance. This is required to access the instance. If you have any problem here make sure that you have selected the public subnet that was created with your VCN.
- In the **Add SSH keys** section, generate an SSH pair or upload your own public key.

  - **Generate a key pair for me** (Recommended): Use this option if you are using running Linux, Mac, or Windows 10/11, otherwise you may need to generate a key using PuTTY. Make sure that you have SSH installed on your device. Once the keys are generated, download them and keep them safe because anyone who has access to the private key can connect to your instance.
  - **Upload public key files** If you generate SSH keys with PuTTY or any similar client, you can upload the keys here.
  - **Paste public keys** paste the public key portion of your key pair in the box

- Leave all options cleared in the **Boot volume** section.
- Click **Create**.
- Provisioning may take a few minutes before the state updates to running.
- Once completed, you can click the instance name to see its details.

  ![running instance](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149678/realm/tutorials/oci-wg-imgs/running-instance_cbgwpm.png)

- Make a note of the public IP address as we'll need this later.

### Connecting to your instance

- We can check if we have been successful by connecting to the instance.
- Open a shell in the directory where your private key is stored.

  - On Windows, you can navigate to the folder in Explorer and then simply type CMD in the address bar and press enter.
  - Check first if you have OpenSSH installed using `ssh -V`

    ![ssh version](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149679/realm/tutorials/oci-wg-imgs/ssh-v-windows_znrgch.png)

  - In Powershell, type the following commands to restrict the permissions on your key file:

    - `icacls.exe your_key_name.key /reset`
    - `icacls.exe your_key_name.key /grant:r "$($env:username):(r)"`
    - `icacls.exe your_key_name.key /inheritance:r`

  - If you still get the error shown below, then make sure that your file is stored in a restricted folder like `C:\Users\<Username>\*`.

    ![uprotected private key file](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149682/realm/tutorials/oci-wg-imgs/unprotected-pvt-key_b1gyqv.png)

- If you're using a UNIX-style system (Linux or MacOS), you can run the following command to ensure that only you can read the private key file `chmod 400 <private_key_file>` . Replace `<private_key_file>` with the name of your key file which should look something like _ssh-key-[date].key_.
- Type the command `ssh -i <private_key_file> <username>@<public-ip-address>` to connect to your instance.

  [ssh command image]

  - `<private_key_file>`: the full path to the private key file. If you are in the same folder, you just need the file name as shown above.
  - `<username>`: the default username for the instance. For ubuntu, it should be \*_ubuntu_.
  - `<public-ip-address>`: this is the external IP of the VM instance that we saved earlier.

- For the first connection, you will need to provide confirmation for the key exchange.

  ![confirmation](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149678/realm/tutorials/oci-wg-imgs/ssh-confirmation_zro7d3.png)

- Once you have successfully connected to your instance, login as root using `sudo su`.
- Make sure that everything is up to date by running the `sudo update` and then `sudo upgrade` commands.

### Allowing UDP traffic

- Before we can configure our VPN, we must first modify the ingress firewall rules to allow our Wireguard traffic.
- Go to **Networking** in the navigation pane.
- Click on the VCN in which your instance is running.
- If you are using the root compartment, you should have 2 subnets: `Private Subnet-<your-vcn-name-here>` and `Public Subnet-<your-vcn-name-here>`
- Click on the public subnet.
- Choose `Default Security list for <your-vcn-name-here>`

  ![ingress rules](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149668/realm/tutorials/oci-wg-imgs/ingress-rules_ponl0h.png)

- Click on `Add Ingress Rules`
- Configure your ingress rules as shown below.

  ![ingress rules config](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149684/realm/tutorials/oci-wg-imgs/wg-ingress-rule_rl5sat.png)

  - By leaving **Source CIDR** as 0.0.0.0/0, we allow traffic from any IP.
  - Destination Port Range is set to 51820 as specified in the Wireguard documentation.
  - The IP Protocol is set to UDP because of the advantages it offers such as greater speed.
  - The description tells us what this ingress rule is for in case we need to remove it in the future.

### Installing the VPN

- We install the VPN using PiVPN, which is a set of shell scripts developed to easily turn your Raspberry Pi into a VPN server.
- It works well with our instance because it is also using an ARM processor.
- Return to your shell window and check that you are still connected to your instance.
- Use `curl -L https://install.pivpn.io | bash` to retrieve the installer from the server.
- This should load the PiVPN Automated Installer as shown above.

  ![PiVPN Automated Installer](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149676/realm/tutorials/oci-wg-imgs/pivpn-installer-welcome_ldrccf.png)

- Press **enter** to confirm your selection.

  ![Static IP Needed](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149678/realm/tutorials/oci-wg-imgs/pivpn-static-ip_jzmyk8.png)

- The next screen tells us that we need a static IP address. This is because our VPN creates a tunnel between your device and the VM instance, which we need to connect to via its public IP. If our IP was dynamic then we would need to always reconfigure our VPN to have the right address. Fortunately, Oracle gives our instance a static public IP which means we don't need to worry about setting up dynamic DNS.
- Press **enter** on subsequent screens until you see this screen.

  ![choose a user](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149678/realm/tutorials/oci-wg-imgs/pivpn-user_ltsd3f.png)

- Use the arrow keys to move the cursor down to `ubuntu`, use **space bar** to make the selection, then **enter** to confirm and continue.
- Press **Enter** to maintain the default port 51820. Select **Yes** to confirm.
- Select **CloudFlare** as your DNS provider.

  ![DNS Provider](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149675/realm/tutorials/oci-wg-imgs/pivpn-dns_lwjdbx.png)

- Select our static IP address.

  ![IP address selection here](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149676/realm/tutorials/oci-wg-imgs/pivpn-ip-select_p1jy1d.png)

- Press **Enter** to generate keys.
- Press **Enter** to confirm unattended upgrades. This is important to ensure that our system is always kept up to date and not vulnerable to attacks.
- Once we see this screen, then the installation is complete.

  ![Installation Complete](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149676/realm/tutorials/oci-wg-imgs/pivpn-inst-complete_tdyupg.png)

- At this point it is recommended to reboot the system. Select **Yes** then **Ok** to confirm reboot.
- After a few seconds, you can run the ssh command again to reconnect to your instance.

### Adding a user

- We can use PiVPN to manually grant access to users on our VPN.
- We can use the `pivpn add` command to add a new user configuration. You'll be prompted to give the user a name.
- Then, we use the command `pivpn -qr` to generate a QR code for the user to connect.

  - This will generate a QR code that you can scan with any of your devices. Ideally, you generate a unique QR code for each one of your devices.

  ![adding user pivpn](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663149666/realm/tutorials/oci-wg-imgs/add-vpn-user_ls3dip.png)

- If you have not already downlaoded the wireguard client, do so.

  ![wireguard client](https://res.cloudinary.com/ta1da-cloud/image/upload/v1663259206/realm/tutorials/oci-wg-imgs/wireguard-client_wtdmze.jpg)

- You can use [this website](https://whatismyip.com) to verify that your VPN is working.

  ### Conclusion

  If you have made it this far and your VPN is working, then well done. If not, try again. I hope you have learned something. Happy surfing!
