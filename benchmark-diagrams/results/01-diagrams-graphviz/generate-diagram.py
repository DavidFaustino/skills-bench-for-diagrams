from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import ECS
from diagrams.aws.database import RDSPostgresqlInstance
from diagrams.aws.storage import S3
from diagrams.aws.security import SecretsManager
from diagrams.aws.integration import SQS, Eventbridge
from diagrams.aws.network import ELB
from diagrams.onprem.client import Users
from diagrams.onprem.gitops import ArgoCD
from diagrams.k8s.compute import Pod

graph_attr = {"fontname": "Helvetica", "fontsize": "13", "splines": "ortho", "nodesep": "0.6", "ranksep": "0.9", "bgcolor": "transparent"}
node_attr = {"fontname": "Helvetica", "fontsize": "11"}
edge_attr = {"fontname": "Helvetica", "fontsize": "10"}

with Diagram("Version inventory - example", show=False, direction="LR", outformat="png",
             filename="inventory-graphviz", graph_attr=graph_attr, node_attr=node_attr, edge_attr=edge_attr):
    user = Users("Corporate browser")

    with Cluster("Central AWS account — ECS or existing K8s", graph_attr={"fontname": "Helvetica"}):
        ingress = ELB("Private ingress + TLS")
        portal = ECS("Web portal + API")
        worker = ECS("Collector worker")
        scheduler = Eventbridge("Scheduler, every 15 min")
        queue = SQS("Queue + DLQ")
        with Cluster("Data", graph_attr={"fontname": "Helvetica"}):
            pg = RDSPostgresqlInstance("PostgreSQL")
            s3 = S3("Sanitized evidence")
        vault = SecretsManager("Secrets vault")

    with Cluster("Environment network — Staging, Homologation, Production", graph_attr={"fontname": "Helvetica"}):
        argo = ArgoCD("ArgoCD API")
        pods = Pod("Kubernetes clusters")

    user >> ingress >> portal
    portal >> [pg, s3]
    scheduler >> queue >> worker
    worker >> vault
    worker >> [pg, s3]
    worker >> Edge(label="HTTPS 443 read-only") >> argo
    argo >> Edge(label="sync") >> pods
