PiggyMetrics Lab (Under Construction 🚧)

This is my personal playground for learning how microservices actually work.

I chose PiggyMetrics https://github.com/sqshq/piggymetrics as my test subject because it has a lot of moving parts—multiple Java services, databases, and message queues—making it perfect for practicing.

Tools I'm Using (And Why)
To keep this lab self-hosted and highly visual, I am setting up the following tools on a local virtual machine:
- The Base (RKE2)
- Networking & Traffic (Cilium & Hubble): Handles all the communication between services. It replaces older tools like MetalLB for local load balancing and lets me see real-time traffic maps using Hubble.
- Automated Deployments (Argo CD): It watches this repository and automatically updates the apps in the cluster whenever I push a change.
- Security & Passwords (Vault, ESO, Cert-Manager): Instead of hardcoding passwords in plain text, I use HashiCorp Vault to hide them. The External Secrets Operator (ESO) securely hands them to Kubernetes, and Cert-Manager sets up HTTPS.
- Logs & Monitoring (Grafana Alloy + LGTM Stack + VictoriaMetrics): Grafana Alloy collects all the data from the cluster. It maps everything into Loki (logs), Tempo (traces), and VictoriaMetrics (metrics) so I can visually track exactly what the apps are doing on Grafana dashboards.
- Storage & Backups (Longhorn + Garage): Longhorn manages disk storage for the databases. I am using Garage (a tiny, fast tool written in Rust) to mimic an AWS S3 bucket so I can practice backing up my data locally.