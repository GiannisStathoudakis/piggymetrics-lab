<h1>PiggyMetrics Lab</h1>

<p>This repository serves as a practical learning environment for deploying and managing microservices, GitOps, and zero-trust infrastructure.</p>

<p>The lab utilizes a fork (<a href="https://github.com/GiannisStathoudakis/piggymetrics-fork">piggymetrics-fork</a>) of <a href="https://github.com/sqshq/piggymetrics">PiggyMetrics</a>, which has been modified and adapted to be as compatible as possible with this infrastructure project. It acts as a comprehensive microservices application featuring multiple Java Spring Boot services and MongoDB instances.</p>

<hr>

<h2>Architecture & Tooling</h2>

<p>To keep this lab fully self-hosted, modular, and highly observable, the infrastructure is built across a <b>2-node local Virtual Machine cluster</b> using the following stack:</p>

<h3>1. Compute & Kubernetes Base</h3>
<ul>
  <li><b>RKE2 (Rancher Kubernetes Engine 2):</b> A lightweight, security-focused Kubernetes distribution serving as the core container orchestrator across the two VMs.</li>
</ul>

<h3>2. CI/CD & Package Management</h3>
<ul>
  <li><b>GitHub Actions:</b> Configured directly in the <a href="https://github.com/GiannisStathoudakis/piggymetrics-fork">app fork repository</a> to automatically build container images for the microservices whenever source code changes are pushed.</li>
  <li><b>GitHub Packages (GHCR):</b> Serves as the central container registry storing all built images.</li>
  <li><b>Custom Helm Charts:</b> Stored alongside the application code in the fork repository. They are used to package and parameterize the PiggyMetrics deployments, configurations, and environment overrides for clean, modular management.</li>
  <li><b>Argo CD:</b> Implements GitOps by continuously monitoring the Helm charts and manifests, automatically synchronizing state changes to the RKE2 cluster.</li>
</ul>

<h3>3. Networking & Edge Gateway</h3>
<ul>
  <li><b>Cilium & Hubble:</b> Provides eBPF-based CNI networking, replaces traditional load balancers with L2 announcements, secures node-to-node traffic via WireGuard encryption, and provides real-time network visibility using Hubble.</li>
  <li><b>Kubernetes Gateway API:</b> Manages North-South ingress routing and TLS termination natively using Cilium's Gateway API controller (<code>Gateway</code> and <code>HTTPRoute</code>).</li>
</ul>

<h3>4. Zero-Trust Security & Identity</h3>
<ul>
  <li><b>HashiCorp Vault:</b> Acts as the centralized secret engine and CA authority, generating dynamic database credentials on demand instead of storing static secrets.</li>
  <li><b>External Secrets Operator (ESO):</b> Bridge between Vault and Kubernetes, automatically syncing ephemeral database credentials into Kubernetes Secrets.</li>
  <li><b>Cert-Manager:</b> Automates TLS certificate issuance and renewal using Vault as the ClusterIssuer.</li>
</ul>

<h3>5. Observability & Telemetry</h3>
<ul>
  <li><b>Grafana Alloy:</b> Collects logs, metrics, and traces across all microservices and cluster nodes.</li>
  <li><b>LGTM Stack + VictoriaMetrics:</b>
    <ul>
      <li><b>Loki:</b> Centralized log aggregation.</li>
      <li><b>Tempo:</b> Distributed tracing across Spring Boot services via OpenTelemetry.</li>
      <li><b>VictoriaMetrics:</b> High-performance metric storage.</li>
      <li><b>Grafana:</b> Unified dashboards for real-time visualization of cluster health and application flow.</li>
    </ul>
  </li>
</ul>

<h3>6. Storage & Backups</h3>
<ul>
  <li><b>Longhorn:</b> Provides persistent block storage for stateful workloads like MongoDB.</li>
  <li><b>Garage S3:</b> A lightweight S3-compatible object store written in Rust, used to emulate AWS S3 for local logs backups.</li>
</ul>