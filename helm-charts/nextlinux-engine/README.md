# Nextlinux Engine Helm Chart

[Instructions for migrating deployments from helm/stable to charts.nextlinux.io](#migrating-to-the-new-nextlinux-charts-repository)

This chart deploys the Nextlinux Engine docker container image analysis system. Nextlinux Engine requires a PostgreSQL database (>=9.6) which may be handled by the chart or supplied externally, and executes in a service-based architecture utilizing the following Nextlinux Engine services: External API, SimpleQueue, Catalog, Policy Engine, and Analyzer.

This chart can also be used to install the following Nextlinux Enterprise services: GUI, RBAC, Reporting, Notifications & On-premises Feeds. Enterprise services require a valid Nextlinux Enterprise license, as well as credentials with access to the private DockerHub repository hosting the images. These are not enabled by default.

Each of these services can be scaled and configured independently.

See [Nextlinux Engine](https://github.com/nextlinux/nextlinux-engine) for more project details.

## Chart Details

The chart is split into global and service specific configurations for the OSS Nextlinux Engine, as well as global and services specific configurations for the Enterprise components.

* The `nextlinuxGlobal` section is for configuration values required by all Nextlinux Engine components.
* The `nextlinuxEnterpriseGlobal` section is for configuration values required by all Nextlinux Engine Enterprise components.
* Service specific configuration values allow customization for each individual service.

For a description of each component, view the official documentation at: [Nextlinux Enterprise Service Overview](https://docs.nextlinux.com/current/docs/overview/architecture/)

## Installing the Nextlinux Engine Helm Chart

### TL;DR

```bash
helm repo add nextlinux https://charts.nextlinux.io
helm install my-release nextlinux/nextlinux-engine
```

Nextlinux Engine will take approximately three minutes to bootstrap. After the initial bootstrap period, Nextlinux Engine will begin a vulnerability feed sync. During this time, image analysis will show zero vulnerabilities until the sync is completed. This sync can take multiple hours depending on which feeds are enabled. The following nextlinux-cli command is available to poll the system and report back when the engine is bootstrapped and the vulnerability feeds are all synced up. `nextlinux-cli system wait`

The recommended way to install the Nextlinux Engine Helm Chart is with a customized values file and a custom release name. It is highly recommended to set non-default passwords when deploying. All passwords are set to defaults specified in the chart. It is also recommended to utilize an external database, rather then using the included postgresql chart.

Create a new file named `nextlinux_values.yaml` and add all desired custom values (see the following examples); then run the following command:

#### Helm v3 installation

```bash
helm repo add nextlinux https://charts.nextlinux.io
helm install <release_name> -f nextlinux_values.yaml nextlinux/nextlinux-engine
```

##### Example nextlinux_values.yaml - using chart managed PostgreSQL service with custom passwords.

*Note: Installs with chart managed PostgreSQL database. This is not a guaranteed production ready config.*

```yaml
## nextlinux_values.yaml

postgresql:
  postgresPassword: <PASSWORD>
  persistence:
    size: 50Gi

nextlinuxGlobal:
  defaultAdminPassword: <PASSWORD>
  defaultAdminEmail: <EMAIL>
```

## Adding Enterprise Components

 The following features are available to Nextlinux Enterprise customers. Please contact the Nextlinux team for more information about getting a license for the Enterprise features. [Nextlinux Enterprise Demo](https://nextlinux.com/demo/)

```txt
    * Role-based access control
    * LDAP integration
    * Graphical user interface
    * Customizable UI dashboards
    * On-premises feeds service
    * Proprietary vulnerability data feed (vulnDB, MSRC)
    * Nextlinux reporting API
    * Notifications - Slack, GitHub, Jira, etc.
    * Microsoft image vulnerability scanning
    * Kubernetes runtime image inventory/scanning
```

### Enabling Enterprise Services

Enterprise services require an Nextlinux Enterprise license, as well as credentials with
permission to the private docker repositories that contain the enterprise images.

To use this Helm chart with the Enterprise services enabled, perform the following steps.

1. Create a Kubernetes secret containing your license file.

    ```bash
    kubectl create secret generic nextlinux-enterprise-license --from-file=license.yaml=<PATH/TO/LICENSE.YAML>
    ```

1. Create a Kubernetes secret containing DockerHub credentials with access to the private Nextlinux Enterprise repositories.

    ```bash
    kubectl create secret docker-registry nextlinux-enterprise-pullcreds --docker-server=docker.io --docker-username=<DOCKERHUB_USER> --docker-password=<DOCKERHUB_PASSWORD> --docker-email=<EMAIL_ADDRESS>
    ```

1. (demo) Install the Helm chart using default values.

    ```bash
    helm repo add nextlinux https://charts.nextlinux.io
    helm install <release_name> --set nextlinuxEnterpriseGlobal.enabled=true nextlinux/nextlinux-engine
    ```

1. (production) Install the Helm chart using a custom nextlinux_values.yaml file - *see the following examples*.

    ```bash
    helm repo add nextlinux https://charts.nextlinux.io
    helm install <release_name> -f nextlinux_values.yaml nextlinux/nextlinux-engine
    ```

### Example nextlinux_values.yaml - installing Nextlinux Enterprise

*Note: Installs with chart managed PostgreSQL & Redis databases. This is not a guaranteed production ready config.*

```yaml
## nextlinux_values.yaml

postgresql:
  postgresPassword: <PASSWORD>
  persistence:
    size: 50Gi

nextlinuxGlobal:
  defaultAdminPassword: <PASSWORD>
  defaultAdminEmail: <EMAIL>
  enableMetrics: True

nextlinuxEnterpriseGlobal:
  enabled: True

nextlinux-feeds-db:
  postgresPassword: <PASSWORD>
  persistence:
    size: 20Gi

nextlinux-ui-redis:
  password: <PASSWORD>
```

## Installing on OpenShift

As of chart version 1.3.1, deployments to OpenShift are fully supported. Due to permission constraints when utilizing OpenShift, the official RHEL postgresql image must be utilized, which requires custom environment variables to be configured for compatibility with this chart.

### Example nextlinux_values.yaml - deploying on OpenShift

*Note: Installs with chart managed PostgreSQL database. This is not a guaranteed production ready config.*

```yaml
## nextlinux_values.yaml

postgresql:
  image: registry.access.redhat.com/rhscl/postgresql-96-rhel7
  imageTag: latest
  extraEnv:
  - name: POSTGRESQL_USER
    value: nextlinuxengine
  - name: POSTGRESQL_PASSWORD
    value: nextlinux-postgres,123
  - name: POSTGRESQL_DATABASE
    value: nextlinux
  - name: PGUSER
    value: postgres
  - name: LD_LIBRARY_PATH
    value: /opt/rh/rh-postgresql96/root/usr/lib64
  - name: PATH
     value: /opt/rh/rh-postgresql96/root/usr/bin:/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  postgresPassword: <PASSWORD>
  persistence:
    size: 50Gi

nextlinuxGlobal:
  defaultAdminPassword: <PASSWORD>
  defaultAdminEmail: <EMAIL>
  openShiftDeployment: True
```

To perform an Enterprise deployment on OpenShift, use the following nextlinux_values.yaml configuration

*Note: Installs with chart managed PostgreSQL database. This is not a guaranteed production ready config.*

```yaml
## nextlinux_values.yaml

postgresql:
  image: registry.access.redhat.com/rhscl/postgresql-96-rhel7
  imageTag: latest
  extraEnv:
  - name: POSTGRESQL_USER
    value: nextlinuxengine
  - name: POSTGRESQL_PASSWORD
    value: nextlinux-postgres,123
  - name: POSTGRESQL_DATABASE
    value: nextlinux
  - name: PGUSER
    value: postgres
  - name: LD_LIBRARY_PATH
    value: /opt/rh/rh-postgresql96/root/usr/lib64
  - name: PATH
     value: /opt/rh/rh-postgresql96/root/usr/bin:/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    postgresPassword: <PASSWORD>
    persistence:
      size: 20Gi

nextlinuxGlobal:
  defaultAdminPassword: <PASSWORD>
  defaultAdminEmail: <EMAIL>
  enableMetrics: True
  openShiftDeployment: True

nextlinuxEnterpriseGlobal:
  enabled: True

nextlinux-feeds-db:
  image: registry.access.redhat.com/rhscl/postgresql-96-rhel7
  imageTag: latest
  extraEnv:
  - name: POSTGRESQL_USER
    value: nextlinuxengine
  - name: POSTGRESQL_PASSWORD
    value: nextlinux-postgres,123
  - name: POSTGRESQL_DATABASE
    value: nextlinux
  - name: PGUSER
    value: postgres
  - name: LD_LIBRARY_PATH
    value: /opt/rh/rh-postgresql96/root/usr/lib64
  - name: PATH
     value: /opt/rh/rh-postgresql96/root/usr/bin:/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    postgresPassword: <PASSWORD>
    persistence:
      size: 50Gi

nextlinux-ui-redis:
  password: <PASSWORD>
```

# Chart Updates

See the nextlinux-engine [CHANGELOG](https://github.com/nextlinux/nextlinux-engine/blob/master/CHANGELOG.md) for updates to Nextlinux Engine.

## Upgrading from previous chart versions

A Helm post-upgrade hook job will shut down all previously running Nextlinux services and perform the Nextlinux database upgrade process using a Kubernetes job. 
The upgrade will only be considered successful when this job completes successfully. Performing an upgrade will cause the Helm client to block until the upgrade job completes and the new Nextlinux service pods are started. To view progress of the upgrade process, tail the logs of the upgrade jobs `nextlinux-engine-upgrade` and `nextlinux-enterprise-upgrade`. These job resources will be removed upon a successful Helm upgrade.

## Chart version 1.15.0

---

Chart version v1.15.0 sets the V2 vulnerability scanner, based on [Grype](https://github.com/nextlinux/grype), as the default for new deployments. **Users upgrading from chart versions prior to v1.15.0 will need to explicitly set their preferred vulnerability provider using `.Values.nextlinuxPolicyEngine.vulnerabilityProvider`.** If the vulnerability provider is not explicitly set, Helm will prevent an upgrade from being initiated.

* Nextlinux Engine image updated to v1.0.0 - [Release Notes](https://engine.nextlinux.io/docs/releasenotes/100/)
* Nextlinux Enterprise image updated to v3.2.0 - [Release Notes](https://docs.nextlinux.com/current/docs/releasenotes/320/)
* Enterprise Feeds - Now uses a PVC for the persistent workspace directory. This directory is used by the vulnerability drivers for downloading vulnerability data, and should be persistent for optimal performance.
* Enterprise Feeds - When enabling the Ruby Gems vulnerability driver, the Helm chart will now spin up an ephemeral Postgresql deployment for the Feeds service to load Ruby vulnerability data.

## Chart version 1.14.0

---

* Nextlinux Engine image updated to v0.10.1 - [Release Notes](https://engine.nextlinux.io/docs/releasenotes/0101/)
* Nextlinux Enterprise image updated to v3.1.1 - [Release Notes](https://docs.nextlinux.com/current/docs/releasenotes/311/)
* Enterprise Feeds - MSRC feeds no longer require an access token. No changes are needed, however MSRC access tokens can now be removed from values and/or existing secrets.

## Chart version 1.13.0

---

* Nextlinux Engine image updated to v0.10.0 - [Release Notes](https://engine.nextlinux.io/docs/releasenotes/0100/)
* Nextlinux Enterprise image updated to v3.1.0 - [Release Notes](https://docs.nextlinux.com/current/docs/releasenotes/310/)
* If utilizing the Enterprise Runtime Inventory feature, the catalog service can now be configured to automatically setup RBAC for image discovery within the cluster. This is configured under `.Values.nextlinuxCatalog.runtimeInventory`

## Chart version 1.12.0

---

* Nextlinux Engine image updated to v0.9.1
* Nextlinux Enterprise images updated to v3.0.0
* Existing secrets now work for Enterprise feeds and Enterprise UI - see [existing secrets configuration](#-Utilize-an-Existing-Secret)
* Nextlinux admin default password no longer defaults to `foobar`. If no password is specified, a random string will be generated.

## Chart version 1.10.0

---
Chart dependency declarations have been updated to be compatible with Helm v3.4.0

## Chart version 1.8.0

---
The following Nextlinux-Engine features were added with this version:

* Malware scanning - see .Values.nextlinuxAnalyzer.configFile.malware
* Binary content scanning
* Content hints file analysis - see .Values.nextlinuxAnalyzer.enableHints
* Updated image deletion behavior

For more details see - https://docs.nextlinux.com/current/docs/engine/releasenotes/080

## Chart version 1.7.0

---
Starting with version 1.7.0, the nextlinux-engine chart will be hosted on charts.nextlinux.io. If you're upgrading from a previous version of the chart, you will need to delete your previous deployment and redeploy Nextlinux Engine using the chart from the Nextlinux Charts repository. 

This version of the chart includes the dependent Postgresql chart in the charts/ directory rather then pulling it from upstream. All apiVersions were updated for compatibility with Kubernetes v1.16+ and the postgresql image has been updated to version 9.6.18. The chart version also updates to the latest version of the Redis chart from Bitnami. These dependency updates require deleting and re-installing your chart. If the following process is performed, no data should be lost.

## Migrating To The New Nextlinux Charts Repository

For these examples, we assume that your namespace is called `my-namespace` and your Nextlinux installation is called `my-nextlinux`.

These examples use Helm version 3 and kubectl client version 1.18, server version 1.18.

### **ENSURE MIGRATION IS PERFORMED SEPARATELY FROM NEXTLINUX ENGINE UPGRADES**

All helm installation steps will include a flag to override the Nextlinux Engine/Enterprise images with your current running version. You can upgrade your version of Nextlinux after moving to the new chart from charts.nextlinux.io. Record the version of your Nextlinux deployment and use it anytime the instructions refer to the Engine Code Version.

### Determine Currently Running Nextlinux Version

To determine the currently running Nextlinux version, connect to the nextlinux-api pod, issue the following command, and record the Engine Code Version:

```bash
[nextlinux@nextlinux-api nextlinux-engine]$ nextlinux-cli system status
Service analyzer (nextlinux-nextlinux-engine-analyzer-7cd9c5cb78-j8n8p, http://nextlinux-nextlinux-engine-analyzer:8084): up
Service apiext (nextlinux-nextlinux-engine-api-54cff87fcd-s4htm, http://nextlinux-nextlinux-engine-api:8228): up
Service catalog (nextlinux-nextlinux-engine-catalog-5898dc67d6-64b8n, http://nextlinux-nextlinux-engine-catalog:8082): up
Service simplequeue (nextlinux-nextlinux-engine-simplequeue-5cc449cc5c-djkf7, http://nextlinux-nextlinux-engine-simplequeue:8083): up
Service policy_engine (nextlinux-nextlinux-engine-policy-68b99ddf96-d4gbl, http://nextlinux-nextlinux-engine-policy:8087): up

Engine DB Version: 0.0.13
Engine Code Version: 0.7.2
```

## If Using An External Postgresql Database (not included as chart dependency)

```bash
helm uninstall --namespace=my-namespace my-nextlinux
helm repo add nextlinux https://charts.nextlinux.io
helm repo update
export NEXTLINUX_VERSION=0.7.2 # USE YOUR ENGINE CODE VERSION HERE
helm install --namespace=my-namespace --set nextlinuxGlobal.image=docker.io/nextlinux/nextlinux-engine:v${NEXTLINUX_VERSION} --set nextlinuxEnterpriseGlobal.image=docker.io/nextlinux/enterprise:v${NEXTLINUX_VERSION} -f nextlinux_values.yaml my-nextlinux nextlinux/nextlinux-engine
```

## If Using The Included Postgresql Chart

When utilizing the included Postgresql chart, you will need to reuse the persistent volume claims that are attached to your current deployment. These existing claims will be utilized when re-installing nextlinux-engine using the new chart from charts.nextlinux.io.

### Determine Your Database PersistentVolumeClaim

Find the name of the database PersistentVolumeClaim using `kubectl`:

```bash
$ kubectl get persistentvolumeclaim --namespace my-namespace
NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
my-nextlinux-postgresql   Bound   pvc-739f6f21-b73b-11ea-a2b9-42010a800176    20Gi       RWO            standard       2d
```

The name of your PersistentVolumeClaim in the example shown is `my-nextlinux-postgresql`. Note that, as you will need it later.

Nextlinux Enterprise users with a standalone Feeds Service will see a different set of PersistentVolumeClaims:

```bash
$ kubectl get persistentvolumeclaim --namespace my-namespace
NAME                                           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
my-nextlinux-nextlinux-feeds-db                    Bound    pvc-cd7ebb6f-bbe0-11ea-b9bf-42010a800020   20Gi       RWO            standard       3d
my-nextlinux-postgresql                          Bound    pvc-cd7dc7d2-bbe0-11ea-b9bf-42010a800020   20Gi       RWO            standard       3d
```

The names of the PersistentVolumeClaims in the example shown are `my-nextlinux-nextlinux-feeds-db` and `my-nextlinux-postgresql`. You may see other persistent volume claims, but only `my-nextlinux-nextlinux-feeds-db` and `my-nextlinux-postgresql` are relevant for this migration. Remember the names, as you will need them later.

#### Uninstall Your Nextlinux Installation With Helm

```bash
$ helm uninstall --namespace=my-namespace my-nextlinux
release "my-nextlinux" uninstalled
```

Nextlinux Enterprise users will want to remove the Redis DB PersistentVolumeClaim. This will delete all current session data but will not affect stability of the deployment:

```bash
kubectl delete pvc redis-data-my-nextlinux-nextlinux-ui-redis-master-0
```

Your other PersistentVolumeClaims will still be resident in your cluster (we're showing results from an Nextlinux Enterprise installation that has a standalone Feeds Service below. Nextlinux Enterprise users without a standalone Feeds Service, and Nextlinux Engine users will not see `my-nextlinux-nextlinux-feeds-db`):

```bash
$ kubectl get persistentvolumeclaim --namespace my-namespace
NAME                          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
my-nextlinux-nextlinux-feeds-db   Bound    pvc-a22abf70-bbb9-11ea-840b-42010a8001d8   20Gi       RWO            standard       3d
my-nextlinux-postgresql         Bound    pvc-e6daf90a-bbb8-11ea-840b-42010a8001d8   20Gi       RWO            standard       3d
```

#### Add The New Nextlinux Helm Chart Repository

```bash
$ helm repo add nextlinux https://charts.nextlinux.io
"nextlinux" has been added to your repositories

$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "nextlinux" chart repository
```

#### Install The Nextlinux Helm Chart

Update your nextlinux_values.yaml file as shown, using the PersistentVolumeClaim values from above:

Engine only deployment values file example:

```yaml
# nextlinux_values.yaml

  postgresql:
    persistence:
      existingclaim: my-nextlinux-postgresql
```

Enterprise deployment values file example:

```yaml
# nextlinux_values.yaml

postgresql:
  persistence:
    existingclaim: my-nextlinux-postgresql

nextlinux-feeds-db:
  persistence:
    existingclaim: my-nextlinux-nextlinux-feeds-db
```

Install a new Nextlinux Engine deployment using the chart from charts.nextlinux.io

```bash
$ export NEXTLINUX_VERSION=0.7.2 # USE YOUR ENGINE CODE VERSION HERE
$ helm install --namespace=my-namespace --set nextlinuxGlobal.image=docker.io/nextlinux/nextlinux-engine:v${NEXTLINUX_VERSION} --set nextlinuxEnterpriseGlobal.image=docker.io/nextlinux/enterprise:v${NEXTLINUX_VERSION} -f nextlinux_values.yaml my-nextlinux nextlinux/nextlinux-engine

NAME: my-nextlinux
LAST DEPLOYED: Thu Jun 25 12:25:33 2020
NAMESPACE: my-namespace
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
To use Nextlinux Engine you need the URL, username, and password to access the API.
...more instructions...
```

Verify that your PersistentVolumeClaims are bound (output may vary):

```bash
$ kubectl get persistentvolumeclaim --namespace my-namespace
NAME                          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
my-nextlinux-nextlinux-feeds-db   Bound    pvc-a22abf70-bbb9-11ea-840b-42010a8001d8   20Gi       RWO            standard       3d
my-nextlinux-postgresql         Bound    pvc-e6daf90a-bbb8-11ea-840b-42010a8001d8   20Gi       RWO            standard       3d
```

Connect to the nextlinux-api pod and validate that your installation still contains all of your previously scanned images.

```bash
[nextlinux@nextlinux-api nextlinux-engine]$ nextlinux-cli image list
Full Tag                                   Image Digest                                                                Analysis Status 
docker.io/alpine:latest                    sha256:a15790640a6690aa1730c38cf0a440e2aa44aaca9b0e8931a9f2b0d7cc90fd65     analyzed
docker.io/nextlinux/nextlinux-engine:latest    sha256:624c9f662233838d1046809135a70ab88d79bd0f2e53dd74bb3d67d10d997bd1     analyzed
docker.io/ubuntu:latest                    sha256:60f560e52264ed1cb7829a0d59b1ee7740d7580e0eb293aca2d722136edb1e24     analyzed
```

You are now running Nextlinux from the new chart repository, with your data in place. 

## Upgrade To Latest Version of Nextlinux

Now that you're migrated to charts.nextlinux.io, you can upgrade Nextlinux Engine to the latest version if desired.

```bash
helm upgrade --namespace my-namespace -f nextlinux_values.yaml my-nextlinux nextlinux/nextlinux-engine
```

# Configuration

All configurations should be appended to your custom `nextlinux_values.yaml` file and utilized when installing the chart. While the configuration options of Nextlinux Engine are extensive, the options provided by the chart are as follows:

## Exposing the service outside the cluster using Ingress

This configuration allows SSL termination using your chosen ingress controller.

#### NGINX Ingress Controller

```yaml
ingress:
  enabled: true
```

#### ALB Ingress Controller

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
  apiPath: /v1/*
  uiPath: /*
  apiHosts:
    - nextlinux-api.example.com
  uiHosts:
    - nextlinux-ui.example.com

nextlinuxApi:
  service:
    type: NodePort

nextlinuxEnterpriseUi:
  service
    type: NodePort
```

#### GCE Ingress Controller

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: gce
  apiPath: /v1/*
  uiPath: /*
  apiHosts:
    - nextlinux-api.example.com
  uiHosts:
    - nextlinux-ui.example.com

nextlinuxApi:
  service:
    type: NodePort

nextlinuxEnterpriseUi:
  service
    type: NodePort
```

## Exposing the service outside the cluster Using Service Type

```yaml
nextlinuxApi:
  service:
    type: LoadBalancer
```

## Utilize an Existing Secret

Secrets should be created prior to running `helm install`. These can be used to override the secret provisioned by the Helm chart, preventing plain text passwords in your values.yaml file.

```yaml
nextlinuxGlobal:
  # The secret should define the following environment vars:
  # NEXTLINUX_ADMIN_PASSWORD
  # NEXTLINUX_DB_PASSWORD
  # NEXTLINUX_SAML_SECRET (if applicable)
  existingSecret: "nextlinux-engine-secrets"


nextlinuxEnterpriseFeeds:
  # The secret should define the following environment vars:
  # NEXTLINUX_ADMIN_PASSWORD
  # NEXTLINUX_FEEDS_DB_PASSWORD
  # NEXTLINUX_SAML_SECRET (if applicable)
  existingSecret: "nextlinux-feeds-secrets"

nextlinuxEnterpriseUI:
  # This secret should define the following ENV vars
  # NEXTLINUX_APPDB_URI
  # NEXTLINUX_REDIS_URI
  existingSeccret: "nextlinux-ui-secrets"
```

## Install using an existing/external PostgreSQL instance

*Note: it is recommended to use an external Postgresql instance for production installs.*

See comments in the values.yaml file for details on using SSL for external database connections.

```yaml
postgresql:
  postgresPassword: <PASSWORD>
  postgresUser: <USER>
  postgresDatabase: <DATABASE>
  enabled: false
  externalEndpoint: <HOSTNAME:5432>

nextlinuxGlobal:
  dbConfig:
    ssl: true
    sslMode: require
```

## Install using Google CloudSQL

```yaml
## nextlinux_values.yaml
postgresql:
  enabled: false
  postgresPassword: <CLOUDSQL-PASSWORD>
  postgresUser: <CLOUDSQL-USER>
  postgresDatabase: <CLOUDSQL-DATABASE>

cloudsql:
  enabled: true
  instance: "project:zone:cloudsqlinstancename"
  # Optional existing service account secret to use.
  useExistingServiceAcc: true
  serviceAccSecretName: my_service_acc
  serviceAccJsonName: for_cloudsql.json
  image:
    repository: gcr.io/cloudsql-docker/gce-proxy
    tag: 1.12
    pullPolicy: IfNotPresent
```

## Archive Driver

*Note: it is recommended to use an external archive driver for production installs.*

The archive subsystem of Nextlinux Engine is what stores large JSON documents, and can consume substantial storage if
you analyze a lot of images. A general rule for storage provisioning is 10MB per image analyzed, so with thousands of
analyzed images, you may need many gigabytes of storage. The Archive drivers now support other backends than just postgresql,
so you can leverage external and scalable storage systems and keep the postgresql storage usage to a much lower level.

### Configuring Compression

The archive system has compression available to help reduce size of objects and storage consumed in exchange for slightly
slower performance and more cpu usage. There are two config values:

To toggle on/off (default is True), and set a minimum size for compression to be used (to avoid compressing things too small to be of much benefit, the default is 100):

```yaml
nextlinuxCatalog:
  archive:
    compression:
      enabled=True
      min_size_kbytes=100
```

### The supported archive drivers are

* S3 - Any AWS s3-api compatible system (e.g. minio, scality, etc)
* OpenStack Swift
* Local FS - A local file system on the core pod. It does not handle sharing or replication, so it is generally only for testing.
* DB - the default postgresql backend

### S3

```yaml
nextlinuxCatalog:
  archive:
    storage_driver:
      name: 's3'
      config:
        access_key: 'MY_ACCESS_KEY'
        secret_key: 'MY_SECRET_KEY'
        #iamauto: True
        url: 'https://S3-end-point.example.com'
        region: null
        bucket: 'nextlinuxarchive'
        create_bucket: True
    compression:
    ... # Compression config here
```

### Using Swift

The Swift configuration is basically a pass-thru to the underlying pythonswiftclient so it can take quite a few different
options depending on your Swift deployment and config. The best way to configure the Swift driver is by using a custom values.yaml.

The Swift driver supports the following authentication methods:

* Keystone V3
* Keystone V2
* Legacy (username / password)

#### Keystone V3

```yaml
nextlinuxCatalog:
  archive:
    storage_driver:
      name: swift
      config:
        auth_version: '3'
        os_username: 'myusername'
        os_password: 'mypassword'
        os_project_name: myproject
        os_project_domain_name: example.com
        os_auth_url: 'foo.example.com:8000/auth/etc'
        container: 'nextlinuxarchive'
        # Optionally
        create_container: True
    compression:
    ... # Compression config here
```

#### Keystone V2

```yaml
nextlinuxCatalog:
  archive:
    storage_driver:    
      name: swift
      config:
        auth_version: '2'
        os_username: 'myusername'
        os_password: 'mypassword'
        os_tenant_name: 'mytenant'
        os_auth_url: 'foo.example.com:8000/auth/etc'
        container: 'nextlinuxarchive'
        # Optionally
        create_container: True
    compression:
    ... # Compression config here
```

#### Legacy Username/Password

```yaml
nextlinuxCatalog:
  archive:
    storage_driver:
      name: swift
      config:
        user: 'user:password'
        auth: 'http://swift.example.com:8080/auth/v1.0'
        key:  'nextlinux'
        container: 'nextlinuxarchive'
        # Optionally
        create_container: True
    compression:
    ... # Compression config here
```

### Using Postgresql

This is the default archive driver and requires no additional configuration.

## Prometheus Metrics

Nextlinux Engine supports exporting prometheus metrics form each container. Do the following to enable metrics:

```yaml
nextlinuxGlobal:
  enableMetrics: True
```

When enabled, each service provides the metrics over the existing service port so your prometheus deployment will need to
know about each pod, and the ports it provides to scrape the metrics.

## Using custom certificates

A secret needs to be created in the same namespace as the nextlinux-engine chart installation. This secret should contain all custom certs, including CA certs & any certs used for internal TLS communication. 
This secret will be mounted to all nextlinux-engine pods at /home/nextlinux/certs to be utilized by the system.

## Event Notifications

Nextlinux Engine in v0.2.3 introduces a new events subsystem that exposes system-wide events via both a REST api as well
as via webhooks. The webhooks support filtering to ensure only certain event classes result in webhook calls to help limit
the volume of calls if you desire. Events, and all webhooks, are emitted from the core components, so configuration is
done in the coreConfig.

To configure the events:

```yaml
nextlinuxCatalog:
  events:
    notification:
      enabled:true
    level=error
```

## Scaling Individual Components

As of Chart version 0.9.0, all services can now be scaled-out by increasing the replica counts. The chart now supports
this configuration.

To set a specific number of service containers:

```yaml
nextlinuxAnalyzer:
  replicaCount: 5

nextlinuxPolicyEngine:
  replicaCount: 3
```

To update the number in a running configuration:

```bash
helm upgrade --set nextlinuxAnalyzer.replicaCount=2 <releasename> nextlinux/nextlinux-engine -f nextlinux_values.yaml
```
