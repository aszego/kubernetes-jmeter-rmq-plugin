# kubernetes-jmeter

This repository contains a modified version of https://github.com/kaarolch/kubernetes-jmeter.
The original contents of README.md is preserved down below with small necessary updates.

## Customizations

* Updated JMeter version to current release.
* Added Rabbit MQ plugin to images from https://github.com/aliesbelik/jmeter-amqp-plugin/releases.
* Added logging and some enhancements to `run-test.sh`.
* Improved JMeter Helm chart:
  * Deployment
    * Uses `nodeSelector` to target a specific node pool (`config.agentpool` in values.yaml, defaults to `jmeter`).
    * Tolerates a configurable taint (`config.tolerateKey`, defaults to `jmeter`) to help disallowing other deployments to use the same node pool.
    * Uses pod anti-affinity to prevent multiple JMeter pods from running on the same node (`config.allowOnePodPerNode`, defaults to `true`).
    * Slave JMeter pod replica count is now 1 by default (`config.slaves.replicaCount`)
  * Volumes
    * Uses a PersistentVolumeClaim to allow storage for JMeter input and output (`config.master.storageClassName`, defaults to `azurefile`).
  * Removed `configMap`-based test files (use volumes instead).
  * Dependencies
    * Removed Grafana and Influxdb soft dependencies.

## Usage

See below for detailed instructions.
However, the following is a quick overview of the commands you can use to run JMeter tests.

1. Create a JMeter pool on AKS; add taint `jmeter=jmeter`.
1. From within /charts/jmeter, run `helm install jmeter ./ -n jmeter`
1. Navigate to the dynamic File Share created in the Storage Account within the AKS cluster's MC_ resource group.
1. Upload the JMeter test plan, including any dependencies (e.g. .csv files) to the File Share.
1. When finished, uninstall the JMeter Helm chart with `helm uninstall jmeter -n jmeter`

## Ideas for further improvements
* Further improvements to consider:
* Factor some values in .jmx into properties.
* Separate single PVC into two:
  * Test input
  * Test logs
* Make PVC permanent (now gets deleted w/ uninstalling the Helm chart).
* Switch to bring-your-own storage account.

## Original README.md text
[![License](https://img.shields.io/badge/license-MIT%20License-brightgreen.svg)](https://opensource.org/licenses/MIT) [![Build Status](https://travis-ci.org/kaarolch/kubernetes-jmeter.svg?branch=master)](https://travis-ci.org/kaarolch/kubernetes-jmeter)

Jmeter test workload inside kubernetes. [Jmeter](charts/jmeter) chart bootstraps an Jmeter stack on a Kubernetes cluster using the Helm package manager.

Currently [jmeter](charts/jmeter) helm chart deploy:
*   Jmeter master
*   Jmeter slaves
*   InfluxDB instance with graphite interface as a jmeter backend
*   Grafana instance

![kubernetes-jmeter stack architecture](images/kubernetes-jmeter_architecture.png)

## Installation
Using helm repo:
```
helm repo add k8s-jmeter https://kaarolch.github.io/kubernetes-jmeter/charts/
```

Old way: Using local copy of git repository:
```
git clone git@github.com:kaarolch/kubernetes-jmeter.git
cd kubernetes-jmeter/charts/jmeter
helm install -n test ./
```
When jmeter chart is installed from local folder `k8s-jmeter/jmeter` should be replace with `./`.

If you would like to provide custom values.yaml you can add `-f` flag.

```
helm install -n test k8s-jmeter/jmeter -f my_values.yaml
```

The command deploys Jmeter on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

If you change deployment name (`-n test`) please update grafana datasource influx `url` inside your custom values.yaml files.

If you already own grafan and influx stack, kuberentes-jmeter could be deployed without those two dependencies.

```
helm install -n test k8s-jmeter/jmeter --set grafana.enabled=false,influxdb.enabled=false
```

## Run sample test

### Manual run
Copy example test

```
kubectl cp examples/simple_test.jmx $(kubectl get pod -l "app=jmeter-master" -o jsonpath='{.items[0].metadata.name}'):/test/

```
Run tests

```
kubectl exec  -it $(kubectl get pod -l "app=jmeter-master" -o jsonpath='{.items[0].metadata.name}') -- sh -c 'AUTO_RUN=true; /run-test.sh'
```

### ~~Run test via configmap~~

~~Upload test as configmap:~~

```
kubectl create configmap one-test --from-file=./examples/simple_test.jmx
```

Deploy test with auto run, if the `config.master.autoRunTests` would be skipped the test need to be trigger as in manual run step.

```
cd ./charts/jmeter
helm install -n test k8s-jmeter/jmeter --set config.master.testsConfigMap=one-test,config.master.autoRunTests=true
```
Logs could be displayed via `kubectl logs` or visualize via grafana:
```
kubectl logs $(kubectl get pod -l "app=jmeter-master" -o jsonpath='{.items[0].metadata.name}')
```
Example logs from master:
```
Sep 20, 2018 8:40:46 PM java.util.prefs.FileSystemPreferences$1 run
INFO: Created user preferences directory.
Creating summariser <summary>
Created the tree successfully using /test/simple_test.jmx
Configuring remote engine: 172.17.0.10
Configuring remote engine: 172.17.0.9
Starting remote engines
Starting the test @ Thu Sep 20 20:40:47 GMT 2018 (1537476047110)
Remote engines have been started
Waiting for possible Shutdown/StopTestNow/Heapdump message on port 4445
summary +   1003 in 00:00:13 =   76.8/s Avg:   148 Min:   123 Max:   396 Err:     0 (0.00%) Active: 16 Started: 16 Finished: 0
summary +    597 in 00:00:05 =  110.8/s Avg:   150 Min:   123 Max:   395 Err:     0 (0.00%) Active: 0 Started: 16 Finished: 16
summary =   1600 in 00:00:18 =   86.7/s Avg:   149 Min:   123 Max:   396 Err:     0 (0.00%)
Tidying up remote @ Thu Sep 20 20:41:06 GMT 2018 (1537476066203)
... end of run
```
Test could be restarted via pod restart:
```
kubectl delete pods $(kubectl get pod -l "app=jmeter-master" -o jsonpath='{.items[0].metadata.name}')
```

## Remove stack

```
helm delete YOUR_RELEASE_NAME --purge
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The default configuration values for this chart are listed in [values.yaml](charts/jmeter/values.yaml).

| Parameter                       | Description                                   | Default                  |
|---------------------------------|-----------------------------------------------|--------------------------|
| `imageCredentials.registry`     | Image repository                              | `docker.com`             |
| `imageCredentials.username`     | Repository user                               | -                        |
| `imageCredentials.password`     | Repository password                           | -                        |
| `image.master.repository`       | Image master repository                       | `kaarol/jmeter-master`   |
| `image.master.tag`              | Image master tag.                             | `test`                   |
| `image.master.pullPolicy`       | Image master pull policy                      | `Always`                 |
| `image.slave.repository`        | Image master repository                       | `kaarol/jmeter-slave`    |
| `image.slave.tag`               | Image master tag.                             | `latest`                 |
| `image.slave.pullPolicy`        | Image master pull policy                      | `Always`                 |
| `config.disableSSL`             | Disable SSL communication between node        | `true`                   |
| `config.master.replicaCount`    | Number of master                              | `1` - currently only one |
| `config.master.restartPolicy`   | Pod restart policy                            | `Always`                 |
| `config.master.autoRunTests`     | Auto run tests after successful deployment          | `flase`                  |
| `image.slave.replicaCount`      | Number of jmeter workers                      | `2`                      |
| `image.slave.restartPolicy`     | Pod restart policy                            | `Always`                 |
| `anotations`                    | Additional annotations                        | `{}`                     |
| `labels`                        | Additional labels                             | `{}`                     |

### Grafana tips
File [grafana.md](docs/grafana.md) would cover all extra tips for config/access grafana charts.

## Project status

Currently kubernetes-jmeter project is able to run some test on distributed slaves but there still is a lot to do. In few days there should be some documentation added to this repo.

## To Do
Everything ;)
1.  Visualization stack (Grafana + influxdb)
*   Add default dashboard after deployment
2.  Helm charts - 80% of base chart
*   (Hold) Auto update influxdb datasource base on release name currently there is fixed test-influx host added.
*   Resource limitation
3.  Jmeter test get from maven (0%)
4.  Jmeter test get from git (20%) - still not push to master
5.  SSL between Jmeter nodes
6.  Documentation (55%)
