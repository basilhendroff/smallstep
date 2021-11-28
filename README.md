# truenas-iocage-smallstep
This script will create an iocage jail on TrueNAS CORE 12.0 with the latest SmallStep release.
## Status
This script will work with TrueNAS CORE 12.0. It's designed to operate on FreeBSD 12.2 or later, which uses [certctl](https://www.freebsd.org/cgi/man.cgi?query=certctl&apropos=0&sektion=0&manpath=FreeBSD+11.4-stable&arch=default&format=html) to manage the local trust store.
## Usage
Use SmallStep for complete certificate lifecycle managment on the local network (private PKI). Use it to manage private TLS/SSL certificates for internal workloads, devices and people. Smallstep supports the ACME protocol, single sign-on, one-time tokens, VM APIs, and other methods for automating certificates.
### Prerequisites
Although not required, it's recommended to create a Dataset named `apps` with a sub-dataset named `smallstep` on your main storage pool.  Many other jail guides also store their configuration and data in subdirectories of `pool/apps/` If this dataset is not present, a directory `/apps/smallstep` will be created in `$POOL_PATH`.
### Installation

Download the repository to a convenient directory on your TrueNAS/FreeNAS system by changing to that directory and running `git clone https://github.com/basilhendroff/truenas-iocage-smallstep`. Then change into the new truenas-iocage-smallstep directory and create a file called smallstep-config with your favorite text editor. In its minimal form, it would look like this:

```
JAIL_IP="192.168.1.199"
DEFAULT_GW_IP="192.168.1.1"
POOL_PATH="/mnt/tank"
```

Many of the options are self-explanatory, and all should be adjusted to suit your needs, but only a few are mandatory. The mandatory options are:

- JAIL_IP is the IP address for your jail. You can optionally add the netmask in CIDR notation (e.g., 192.168.1.199/24). If not specified, the netmask defaults to 24 bits. Values of less than 8 bits or more than 30 bits are invalid.
- DEFAULT_GW_IP is the address for your default gateway
- POOL_PATH is the path for your data pool.

In addition, there are some other options which have sensible defaults, but can be adjusted if needed. These are:

- JAIL_NAME: The name of the jail, defaults to "smallstep"
- DATA_PATH: This is the path for SmallStep data storage, defaults to `$POOL_PATH/apps/smallstep`. It is mounted inside the jail at `/var/db/step_ca`. 
- INTERFACE: The network interface to use for the jail. Defaults to `vnet0`.
- VNET: Whether to use the iocage virtual network stack. Defaults to `on`.

### Execution

Once you've downloaded the script and prepared the configuration file, run this script (`./smallstep-jail.sh`). The script will run for several minutes. When it finishes, your jail will be created and SmallStep will be installed.

