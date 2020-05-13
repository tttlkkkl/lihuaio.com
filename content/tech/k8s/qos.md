---
title: "k8s服务质量调优"
date: 2020-05-13T10:31:23+08:00
draft: false
tags:
- k8s
- ops
dropCap: true
indent: instead
---

### 引言

从`docker swarm`迁移到`k8s`已经有一段时间，花了很大的时间和精力，期间有过三次磁盘挂载异常的灾难级故障，而后又有周期性的节点故障。由于日常紧急开发任务比较多，每次遇到故障都是直接移除节点再添加，或者在开发和测试环境直接是强制重启节点以恢复正常运行。起初猜测是没有进行服务质量等级调优导致个别节点被调度太多服务，导致节点宕机。后面一次深入查证果然是因为内存溢出导致的各种诡异问题的出现。现在有时间回头处理这个事情了。记录之。本文只能作为调优思路上的一些参考。

### 关于服务质量

我的理解是，服务质量即提供高效、稳定的服务的能力，这应该作为每个服务的终极目标。在比较有限的硬件资源支持下通过调优使服务有更高的稳定性。就k8s可以通过对关键服务，比如数据库、服务注册发现服务、网关等进行更优先的资源分配，同时通过 `nodeSelector`（节点选择）、亲和性`（Affinity）/反亲和性（anti-affinity）`、`容忍（Taints）/污点（tolerations）`等调度策略的设置将关键服务调度到资源更加充足的节点，其余非关键服务可以通过设置服务质量等级`（QoS）`让`k8s`进行最优调度。保证在资源紧张的时候，重要服务优先运行，避免关键服务宕机导致所有关联服务不可用，其他"非重要"服务可以等待资源的弹性伸缩完成后恢复服务。

### 服务现状以及调优过程

服务质量等级以及pod调度策略相关资料是很完善的，不再赘述。本文直接结合实际场景记录调优过程，旨在分享一个建议的调优思路和经验。

上`k8s`之后将开发环境和测试环境也直接上云，本地通过`telepresence`工具连接`k8s`以实现本地开发和调试。可以先根据服务重要程度进行排序再根据服务大致的资源占用指标确定调优方案。本文以我司开发环境和测试环境所在的集群为例。

#### `k8s`命名空间划分如下：

|命名空间|用途|
|---|---|
|cert-manager|部署证书管理相关服务|
|cicd-system|运行流水线、私有镜像仓库等运维相关服务|
|default|默认命名空间，主要运行`telepresence`的服务端`pod`|
|dev|运行开发环境完整服务、包括数据库、服务注册与发现等`关键服务`|
|istio-system|运行`istio`关键服务，包括网关|
|kube-public|默认命名空间，没有作用|
|kube-system|默认命名空间，运行`k8s`系统服务|
|testing|运行测试环境完整服务|
|harbor-online|运行harbor面向公网的服务（内网服务运行在cicd-system命名空间中）。|

#### 关键服务排序(除去 kube-system 从最重要往后排序)
因为`kube-system`是系统命名空间，我们暂时假设其中的服务都是经过质量等级调优的（事实上也是如此），所以暂时不予考虑。

|服务名称|所在命名空间|用途|
|---|---|---|
|postgresql|cicd-system|为私有仓库harbor、drone等服务提供存储支持|
|redis|cicd-system|为私有仓库harbor提供镜像层数据缓存支持|
|harbor|cicd-system|为整个公司提供私有镜像存储服务，本服务异常可能导致线上服务因不能拉取镜像而无法启动|
|drone|cicd-system|为cicd流水线提供镜像打包、自动部署支持|
|mysql|cicd-system|为其他运维服务提供数据库支持|
|mongodb|cicd-system|为其他运维服务提供数据支持|
|istio-ingressgateway|istio-system|为开发环境以及运维服务提供网关服务|
|istio-second-ingressgateway|istio-system|为测试环境提供网关服务|
|istio-pilot|istio-system|为istio提供配置服务|
|nginx-proxy|istio-system|为部分运维服务提供认证代理服务|
|cert-manager|cert-manager|为集群提供证书管理服务|
|alidns|cert-manager|为集群acme证书签发提供阿里dns操作服务|
|mysql|dev|为开发环境提供数据库服务|
|redis|dev|为开发环境服务提供缓存服务|
|consul|dev|为开发环境提供服务注册发现服务|
|nsq|dev|为开发环境提供队列服务|
|mysql|test|为测试环境提供数据库服务|
|redis|test|为测试环境服务提供缓存服务|
|consul|test|为测试环境提供服务注册发现服务|
|nsq|test|为测试环境提供队列服务|

以上是根据服务重要程度列出的大致的集群服务列表，都是基础支撑服务。可以通过类似的方式对其他业务服务按照重要程度排序，然后实施服务质量等级调整。

#### 进一步分析
- 由于`harbor`可能会直接影响到线上服务，所以首先要确保`harbor`的稳健运行。其次是`drone`等支撑运维服务，因为服务宕机会影正常的开发和部署流程。如此，最先保证稳定运行的是`cicd-system`命名空间中的数据库服务。原因很简单，钥如果数据库服务无法支持那么以上所说的运维支撑服务都会宕机。
- 网关是所有服务公网流量的代理，在保证关键服务运行之后要保证网关的正常，才能保障上述关键服务能够对外提供服务。
- `nginx-proxy` 为部分本身没有提供鉴权的运维相关服务提供鉴权代理，所以`nginx-proxy`要优先保证运行，鉴于其自身资源消耗比较小可以酌情降低资源分配优先级。
- `cert-manager`和`alidns`提供了证书的管理服务，但是如果不是服务宕机期间有过期证书或者新证书请求的发生，不会影响大面积影响整体服务，可酌情降级。
- 接着是开发环境和测试环境的数据库服务还有服务注册发现服务，要优先保证服务的正常否则会导致开发和测试环境服务的大面积不可用。无限重启等在导致正常开发活动无法正常的同时，会因为新旧服务同时存在导致资源消耗成倍增长。导致服务恢复时间和难度大大增加。
- 在资源允许的条件下保证队列服务正常运行，这并不是说队列服务不重要，而是因为其只是用于开发和测试活动，不可用造成的影响相对于线上要小很多。

总之就是要在现有资源和提供稳定服务之间取一个相对平衡的点。当然如果你手头又很多闲置的资源的话可以直接无视这些精细规划。

#### 实施调整
##### 对命名空间资源的整体限制
- 首先确定`kube-public`是个无用命名空间，又因为是系统默认创建所以不予删除，而是象征性的予以资源限制，避免因权限控制不当被开发者部署无用服务导致资源浪费。
```yml
# 限制总cpu和内存
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-quota
  namespace: kube-public
spec:
  hard:
    requests.cpu: 500m
    requests.memory: 500Mi
    limits.cpu: "1"
    limits.memory: 1Gi
```
- 开发可测试环境会部署很多服务，但是在服务部署之初又无法确定其资源消耗，为了避免因`内存`和`cpu`申请过大导致后资源被大量闲置，对开发和测试环境设置默认资源申请参数"
```yml
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
  namespace: dev
spec:
  limits:
  - max:
      cpu: 2000m
    min:
      cpu: 1m
    defaultRequest:
      cpu: 1m
      memory: 50Mi
    type: Container
---
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
  namespace: testing
spec:
  limits:
  - max:
      cpu: 2000m
    min:
      cpu: 1m
    defaultRequest:
      cpu: 1m
      memory: 50Mi
    type: Container
```
##### 划分节点
- 接下来按照分析先调整`cicd-system`中的关键服务:
- 为了提升服务恢复速度（在出现内存溢出或者其他错误时直接重启节点，注意：此操作线上环境，线上环境应该更加精细规范）,将更关键的服务调度到特定节点。
    查看节点列表，并设置标签：
    ```shell
    kubectl get nodes
    ```
    输出:
    ```shell
    cn-shenzhen.192.168.81.154   Ready    <none>   80d   v1.14.8-aliyun.1
    cn-shenzhen.192.168.81.155   Ready    <none>   95d   v1.14.8-aliyun.1
    cn-shenzhen.192.168.81.156   Ready    <none>   76d   v1.14.8-aliyun.1
    ```
    刚好3个工作节点，如此我们可以设置`svc`标签其值分别为`基础服务(base)`、`重要服务(important)`、`一般服务(commonly)`，作为亲和性的调度依据。由于是测试环境，我们还是希望可以多节省一些成本所以只做亲和性设置。线上可以考虑加入反亲和性、污点设置在“浪费”一些资源的情况下更大程度的提升服务稳定性。当然按照以上分析，关键服务在设置资源限制的同时还要直接通过`nodeSelector`调度到基础服务节点。
    ```shell
    kubectl label nodes  cn-shenzhen.192.168.81.154 svc=base
    kubectl label nodes  cn-shenzhen.192.168.81.155 svc=important
    kubectl label nodes  cn-shenzhen.192.168.81.156 svc=commonly
    # 备注：删除标签用 kubectl label nodes  cn-shenzhen.192.168.81.156 svc-
    # 即标签名后跟横杆"-"
    ```
##### 具体调整调度示例
`kubectl top pod -n cicd-system` 查看命名空间中服务的资源占用情况作为`requests`参数参考。在此基础上按照服务特性（是否会需要更多资源）酌情提升,就此作为`limits`参数.
 输出:
```shell
NAME                                           CPU(cores)   MEMORY(bytes)   
cicd-system-apps-micro-865dbb885b-v9l4b        0m           13Mi            
database-postgresql-0                          17m          76Mi            
deploy-micro-5f5bc6fdf6-m2lp9                  0m           11Mi            
drone-drone-server-b49d8dc5d-gqqzk             1m           25Mi            
drone-job-4210-ua1nvvjnc1dwjjd2f-qjlfn         15m          48Mi            
drone-kubernetes-secrets-5595cdc887-zblwn      0m           7Mi             
harbor-harbor-clair-6c465dd8df-4tlpx           138m         3532Mi          
harbor-harbor-clair-6c465dd8df-7sc5b           0m           6Mi             
harbor-harbor-clair-6c465dd8df-z2xcf           0m           76Mi            
harbor-harbor-core-74cbff77d8-bjhwl            4m           22Mi            
harbor-harbor-core-74cbff77d8-h4ltn            2m           13Mi            
harbor-harbor-core-74cbff77d8-hc992            3m           15Mi            
harbor-harbor-jobservice-7f6899bd7c-rsfpj      1m           10Mi            
harbor-harbor-nginx-6b7c767577-jvbl8           2m           3Mi             
harbor-harbor-notary-server-5f67d598c5-wvg87   0m           9Mi             
harbor-harbor-notary-signer-74c78878b4-4d7m8   0m           10Mi            
harbor-harbor-portal-f4b9b65cb-7klwd           0m           3Mi             
harbor-harbor-registry-7dcd6fcdd8-8vqnh        7m           32Mi            
harbor-harbor-registry-7dcd6fcdd8-cqmh8        14m          107Mi           
harbor-harbor-registry-7dcd6fcdd8-klk8q        0m           59Mi            
mongodb-5ddd5b4665-nwx44                       27m          89Mi            
mysql-server-754c9ddd7d-svvkd                  5m           181Mi           
redis-server-master-0                          15m          8Mi  
```
将最关键服务`postgresql`,`redis`,`harbor`,`drone`调度到基础服务节点，并设置资源限制:
以`postgresql`为例，由于`postgresql`是通过`helm`安装的，所以要先得到其`values.yml`文件以确定如何配置:
```helm
#当然最好的办法还是去查看源`chart`包中的定义。
helm inspect stable/postgresql
```
根据说明，在`values.yml`文件中添加以下内容:
```yml
master:
  nodeSelector:
    svc: base
slave:
  nodeSelector:
    svc: base
resources:
  limits:
    cpu: 100m # 备注：1m cpu相当于1核的千分之一
    memory: 500Mi
  requests:
    cpu: 17m
    memory: 76Mi
```
更新之:
```shell
helm upgrade  postgresql stable/postgresql -f values.yml
```
按照以上规划的思路和方式对集群进行服务质量调优，后续根据需要再进行相应的调整。就`k8s`提供的强大的调度管理能力完全可以提供稳定的服务。

在进行服务质量调整的时候尽量先将集群可用资源临时性的扩容，还应注意集群运行状况，避免造成服务停止。