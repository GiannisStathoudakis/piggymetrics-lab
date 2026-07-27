# Spring Boot & Kafka Streams Microservices Lab

> **Note on Repository Name:** This repository is named `piggymetrics-lab` because it originally hosted a [PiggyMetrics](https://github.com/sqshq/piggymetrics) deployment. The lab has since been heavily upgraded to use the Spring Boot Kafka Streams Demo. The repository name has been kept intact to prevent breaking existing GitOps continuous deployment pipelines in Argo CD.

This repository serves as a practical learning environment for deploying and managing event-driven microservices, GitOps, and zero-trust infrastructure.

The lab utilizes a fork ([microservices-demo-fork](https://github.com/GiannisStathoudakis/springboot-kafka-streams-microservices-demo)) of [ZaTribune's Spring Boot Kafka Streams Demo](https://github.com/ZaTribune/springboot-kafka-streams-microservices-demo), which has been modified and adapted to be as compatible as possible with this infrastructure project. It acts as a comprehensive e-commerce microservices application featuring multiple Java Spring Boot services, MySQL databases, and real-time event streams.

---

## Architecture & Tooling

To keep this lab fully self-hosted, modular, and highly observable, the infrastructure is built across a **2-node local Virtual Machine cluster** using the following stack:

### 1. Compute & Kubernetes Base
* **RKE2 (Rancher Kubernetes Engine 2):** A lightweight, security-focused Kubernetes distribution serving as the core container orchestrator across the two VMs.

### 2. CI/CD & Package Management
* **GitHub Actions:** Configured directly in the [app fork repository](https://github.com/GiannisStathoudakis/springboot-kafka-streams-microservices-demo) to automatically build container images for the microservices whenever source code changes are pushed.
* **GitHub Packages (GHCR):** Serves as the central container registry storing all built images.
* **Custom Helm Charts:** Stored alongside the application code in the fork repository. They are used to package and parameterize the microservice deployments, configurations, and environment overrides for clean, modular management.
* **Argo CD:** Implements GitOps by continuously monitoring the Helm charts and manifests, automatically synchronizing state changes to the RKE2 cluster.

### 3. Networking & Edge Gateway
* **Cilium & Hubble:** Provides eBPF-based CNI networking, replaces traditional load balancers with L2 announcements, secures node-to-node traffic via WireGuard encryption, and provides real-time network visibility using Hubble.
* **Kubernetes Gateway API:** Manages North-South ingress routing and TLS termination natively using Cilium's Gateway API controller (`Gateway` and `HTTPRoute`).

### 4. Zero-Trust Security & Dynamic Credentials
* **HashiCorp Vault:** Acts as the centralized secret engine and CA authority. Instead of storing static database passwords, Vault dynamically generates short-lived, ephemeral MySQL credentials on demand, utilizing modern `caching_sha2_password` authentication.
* **External Secrets Operator (ESO):** Acts as the bridge between Vault and Kubernetes, automatically fetching and mapping these dynamic credentials into Kubernetes Secrets (utilizing single-call `dataFrom` templates to ensure perfect credential pairing).
* **Cert-Manager:** Automates TLS certificate issuance and renewal using Vault as the ClusterIssuer.

### 5. Messaging & Data State
* **Redpanda:** A lightweight, highly performant, C++ based drop-in alternative to Apache Kafka. It eliminates the need for ZooKeeper and JVM overhead while serving as the event-streaming backbone for the Spring Boot Kafka Streams topologies (Orders, Payments, Stock).
* **MySQL 8.0+:** Serves as the relational database backend for the microservices, populated securely and dynamically via Vault.

### 6. Observability & Telemetry
* **Grafana Alloy:** Collects logs, metrics, and traces across all microservices and cluster nodes.
* **LGTM Stack + VictoriaMetrics:**
  * **Loki:** Centralized log aggregation.
  * **Tempo:** Distributed tracing across Spring Boot services via OpenTelemetry.
  * **VictoriaMetrics:** High-performance metric storage.
  * **Grafana:** Unified dashboards for real-time visualization of cluster health and application flow.

### 7. Storage & Backups
* **Longhorn:** Provides persistent block storage for stateful workloads like MySQL and Redpanda.
* **Garage S3:** A lightweight S3-compatible object store written in Rust, used to emulate AWS S3 for local logs and backups.