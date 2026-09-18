# Styles already collected

Pasted from `shapesearch.py` and used in `examples/complete-example.drawio`. For any
component outside this list, run the search — do not infer the name by analogy.

```bash
python3 scripts/shapesearch.py "<service>" --limit 3
```

## Containers

The common prefix is `mxgraph.aws4.group`, and what changes is `grIcon`. All of them need
`container=1;pointerEvents=0;collapsible=0;recursiveResize=0`.

| Container | `grIcon` | Stroke | Fill |
| --- | --- | --- | --- |
| AWS Cloud | `group_aws_cloud` | `#232F3E` | none |
| VPC | `group_vpc2` | `#8C4FFF` | none |
| Private subnet | `group_security_group` | `#00A4A6` | `#E6F6F7` |
| Corporate data center | `group_corporate_data_center` | `#7D8998` | none |

Complete example of a container:

```
outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=13;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_vpc2;strokeColor=#8C4FFF;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#8C4FFF;dashed=0;
```

## Service icons

They all follow the same template, swapping `resIcon` and `fillColor`. The default size is 78×78, and the
label sits underneath.

```
sketch=0;outlineConnect=0;fontColor=#232F3E;fillColor=<COLOR>;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.<ICON>;
```

| Service | `resIcon` | `fillColor` |
| --- | --- | --- |
| ECS | `ecs` | `#ED7100` |
| Application Load Balancer | `application_load_balancer` | `#8C4FFF` |
| NAT Gateway | `nat_gateway` | `#8C4FFF` |
| Direct Connect | `direct_connect` | `#8C4FFF` |
| RDS | `rds` | `#C925D1` |
| S3 | `s3` | `#7AA116` |
| Secrets Manager | `secrets_manager` | `#DD344C` |
| SQS | `sqs` | `#E7157B` |
| EventBridge Scheduler | `eventbridge_scheduler` | `#E7157B` |
| EKS | `eks` | `#ED7100` |
| Users | `users` | `#232F3E` |

The color is not decorative: it is the color of the service family in the AWS notation. Orange is compute,
purple is network, magenta is database, green is storage, red is security, pink is integration.

## Components that are not AWS

There is no official ArgoCD shape in the index. For those, use a rounded rectangle with a neutral
color and an explicit label, instead of forcing a similar-looking icon:

```
rounded=1;whiteSpace=wrap;html=1;fillColor=#FAECE7;strokeColor=#993C1D;fontColor=#712B13;fontSize=12;verticalAlign=middle;
```

Kubernetes has an icon in the index, but the search returns Azure and Alibaba variants before the
generic one. Check the result before pasting.

## Edges

```
edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#5A6C86;
```

To highlight the main path — the flow the presentation is going to narrate — change only the stroke
color, keeping everything else the same. Green `#1D9E75` works well over the colored icons.
