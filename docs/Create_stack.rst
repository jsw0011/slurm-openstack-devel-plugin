=============================
Create stack in Openstack GUI
=============================

Download/Clone REPO from:
=========================

https://github.com/jsw0011/slurm-openstack-devel-plugin

In Openstack:
=============

https://openstack.msad.it4i.lexis.tech/project/stacks/

Create a new stack with ``Launch Stack``
----------------------------------------

* In dialog ``Select Template`` choose ``Template File`` – ``Select file``
* Template file is located in ``REPO -> Openstack_init -> slurm-company.yml``
* Click ``next`` after selecting file

Fill the form – examples
------------------------
* Stack name – ``IO-SEA_stack``
* Creation timeout – ``60``
* Password for user – ``your password for openstack``
* Flavor of the compute nodes – ``normal``
* OS image - ``CentOS-Stream-8_20210210``
* Network - ``iosea_network``
* Git project address - ``https://github.com/jsw0011/slurm-openstack-devel-plugin.git``
* Key Name for New Key Pair - ``abc_slurm_boot_demo``
* Existing Key Name for controller - ``abc0014`` – *If you don’t have created, you have to add your key pair in* ``Compute -> Key pairs``
* Click on ``launch``

Add floating IP adress
----------------------
* In Network select ``Floating IPs``
* Right corner select ``Allocate IP to Project``
* Select ``vlan109_adas`` and type description
* Click ``Allocate IP``
* Now click to ``Associate`` and select a port to ``Your Stack Name-Stack-master_node...`` 
* Click ``Associate``

Add Security groups
-------------------
* Click on ``Compute -> Instances``
* Select master_node and under the arrow select ``Security groups``
* Add ``SSH``

Now you are able to connect to the Master node 
----------------------------------------------
* Use IP floating adress
* User ``centos``
* Your ssh key

After connect
-------------
* Wait for building the compute1 and compute2
* You can check it by type ``tail -f /var/log/cloud-init-output.log``
* At the end will appear ``PLAY RECAP*******************``, duration is about 20 minutes
* Now you can run your job by ``sbatch ./your_script.py``
* For check your job type ``squeue --me``
* For other commands see - ``https://docs.ycrc.yale.edu/clusters-at-yale/job-scheduling/``




