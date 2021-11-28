# truenas-iocage-smallstep
This script will create an iocage jail on TrueNAS CORE 12.0 with the latest SmallStep release.
## Status
This script will work with TrueNAS CORE 12.0. It's designed to operate on FreeBSD 12.2 or later, which uses [certctl](https://www.freebsd.org/cgi/man.cgi?query=certctl&apropos=0&sektion=0&manpath=FreeBSD+11.4-stable&arch=default&format=html) to manage the local trust store.
## Usage
Use SmallStep for complete certificate lifecycle managment on the local network (private PKI). Use it to manage private TLS/SSL certificates for internal workloads, devices and people. Smallstep supports the ACME protocol, single sign-on, one-time tokens, VM APIs, and other methods for automating certificates.
### Prerequisites
Although not required, it's recommended to create a Dataset named `apps` with a sub-dataset named `smallstep` on your main storage pool.  Many other jail guides also store their configuration and data in subdirectories of `pool/apps/` If this dataset is not present, a directory `/apps/smallstep` will be created in `$POOL_PATH`.
