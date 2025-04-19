---
title: Provision Your Vagrant Development Environment with Bash Scripting
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: http://res.cloudinary.com/ta1da-cloud/image/upload/v1682080360/realm/covers/Provision%20Your%20Vagrant%20Development%20Environment%20with%20Bash%20Scripting.jpg
tags: ["Tutorial"]
description: In this tutorial, I show you how to leverage the power of BASH scripting to provision your development environment.
publishDate: 2023-04-21
---

# Introduction

As developers, one thing that we find ourselves doing frequently when working on software projects is setting up development environments. With all the advancements happening in DevOps, we are spoiled for choice when it comes to this. Regardless, setting up an environment can be tedious and time consuming, especially when you just want to get to work. Oftentimes they require complex OS configuration, software dependencies, and other settings.

We have all probably heard the words 'it works on my machine' from a colleague when a program refuses to run. When working as part of a team, it's important that we have consistent development environments that can easily be replicated by everyone. This will ensure that everyone is working with the same set of tools and configurations, thereby reducing the number of variables when we do eventually encounter some issues. In this tutorial, we will explore how to use _Vagrant_ and _bash scripting_ to automate the process of creating and configuring a development environment for a simple _Flask_ application. This will help to ensure consistency across development environments and streamline the process of setting up a new development machine.

# Requirements

Before we begin, make sure you have the following software installed on your computer:

- [Vagrant](https://www.vagrantup.com/downloads)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- A text editor of your choice.

# Background

I'll start by briefly explaining what Vagrant and bash scripting are and why we will be using them.

Vagrant is an open-source tools that allows you to create and manage virtual machines on your machine. We all know that it is generally advisable to make our development environments as close to the production environment as possible. Vagrant makes it easy to set up and configure a production-like environment on your machine, regardless of operating system. This means that you can use the same tools and workflow is development and production.

But Vagrant alone isn't enough. We also need a way to ensure that our program's dependencies are installed correctly and ready to use. This is where bash scripting comes in. Bash scripting is a powerful tool that allows you to automate your tasks and streamline your development process. It's a command language interpreter that's used on Linux and Mac systems to perform a wide range of tasks, from simple file manipulation to complex system administration tasks. With the help of bash scripting, you can automate repetitive tasks and create a consistent development environment that works on any system.

With these tools, we can easily create, configure, and manage our development environments with confidence that they will be easy to replicate.

## Setting Up the Project

Create a new directory for your project and navigate into it:

```bash
mkdir myapp
cd myapp
```

_If you're not using Vagrant and just want to skip to the bash scripting you can skip this section_

### Vagrant Set Up

Create a new `Vagrantfile` in the project. A Vagrantfile is a configuration file that defines the environment that Vagrant is going to set up. It allows you to specify things like the base image to use (known as the _box_), the number of VMs to create, networking, shared folders, and any provisioning scripts to run. You can use `vagrant init` to generate the default Vagrantfile, create one from scratch, or use a template. You can create a file called `Vagrantfile` and copy the one below for this tutorial:

```yml
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.network "forwarded_port", guest: 5000, host: 5000

  config.vm.synced_folder "~/Tutorials/flask-demo", "/home/vagrant/myapp", type: "rsync", rsync__exclude: [".git/"]

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.vm.provision "shell", path: "provision.sh"
end
```

This Vagrantfile uses an Ubuntu 18.04 base image with 1 CPU and 1024MB of RAM. We will be running our Flask app on port 5000, so we will set up port forwarding between the host and guest. We also configure the shared folder with rsync enabled to allow us to make changes locally and have our folders reflect on the server. We can also exclude some files and folders to avoid syncing any unnecessary files. We have the option to specify the provider in the Vagrantfile or pass it as a flag when we run `vagrant up`. The second option may provide more flexibility. The script will provision the machine using the `bootstrap.sh` script which we will now proceed to create.

### Bash Scripting

Create a new file named `bootstrap.sh` in the project directory with the following contents:

```bash
#!/usr/bin/env bash

# Check if myapp directory exists, and create it if it doesn't
if [ ! -d "/home/vagrant/myapp" ]
then
    mkdir /home/vagrant/myapp
fi

cd /home/vagrant/myapp

# Update package manager and install necessary packages
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv

# Create virtual environment
python3 -m venv /home/vagrant/myapp/venv
source /home/vagrant/myapp/venv/bin/activate

# Install Flask and other dependencies
pip install Flask

# Create Flask app
cat <<EOF > /home/vagrant/myapp/src/app.py
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello World!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Change permissions to allow anyone to update the app.py file
sudo chmod 777 /home/vagrant/myapp/src/app.py

# Start the app
nohup python3 /home/vagrant/myapp/src/app.py >/dev/null 2>&1 &

echo "Flask app running on http://localhost:5000"
```

You can probably see that this script is not that difficult to understand. We check if the project directory exists, and if it doesn't then it will be created. After updating the package manager and installing our dependencies, we can create the virtual environment for our app. This is not strictly necessary but it is still a good practice. This allows us to have multiple projects that require different versions of the same dependencies without any problems. The playbook also creates the simple app with a single route that returns the string 'Hello World'. The script will also update the permissions on our `app.py` file.

**Note that setting permissions to 777 is not advisable in production as it will allow anyone to update the file.**

When we run our server, we add the `nohup` Unix command which allows us to disconnect from the shell session and still have the command continue to run. The `&` at the end puts the process in the background so that we can continue to use the shell while the process is running.

# Run the App

We use the `vagrant up` command to create and provision the Vagrant environment. This process will download the box if it is not found on your machine and use the bash script to install all dependencies and create our Flask app.

Once the environment is up and running, you can open your browser and navigate to `http://localhost:5000`. You should see a "Hello World!" message.

![Hello World](https://res.cloudinary.com/ta1da-cloud/image/upload/v1682080236/realm/tutorials/vagrant-flash-bash-scripting/hello-world_vwrbmd.png)

Now, you can navigate to the local synced folder, open your app in any text editor of your choice, make some changes, refresh your browser and see the updates immediately.

# Conclusion

Congratulations! You have just set up a simple Flask application in a Vagrant environment using a bash script. I hope your Flask application grows into something cool, or you can use what you've learned here to create a different script that fits your needs. If you have any thoughts or feedback, you can reach out to me on [Twitter](https://twitter.com/edtha3rd) and you can follow my [Instagram](https://instagram.com/fullstackmaverick) for more developer content.
