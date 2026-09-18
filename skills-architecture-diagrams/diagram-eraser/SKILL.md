---
name: diagram-eraser
description: Generates technical diagrams in PNG or HTML from a JSON in which every element has an explicit position, with automatic line routing and technology icons, using the Eraser Diagrams CLI. Use when you want to control the layout but do not want to compute the path of the arrows.
license: MIT
allowed-tools: [Bash, Read, Write]
---

# Diagram with the Eraser CLI

Replicates test 04 of the package. The division of labor is: you position the elements, the
tool routes the lines around the obstacles, resolves icons, measures the text and renders.
The render cycle is a little over a second, so iterating is cheap.

## When not to use it

When the deliverable has to be editable by another person in a graphical tool, or when the
machine cannot fetch the icons over the network. In those cases, use `../architecture-drawio/`.

## Setup, once

```bash
npm i -D @eraserlabs/diagrams-cli
```

It requires Node 22.12+ and an installed Chromium — on macOS, Google Chrome works. The icons come from
Eraser's public bucket on every render: the JSON does not leave the machine, but the render needs the
network. For offline or corporate use, point `icons.baseUrl` at an internal mirror in the
`eraser-diagrams.config.json` file.

## Workflow

1. Assemble the JSON. Every entity needs `id`, `x` and `y`; `width` and `height` are minimums, and the
   content can grow beyond them. A connection is just `{"from": "a", "to": "b"}` — `tag` and `id`
   are optional. Containers use `"tag": "Group"` with `isContainer: true`, and the children
   point at it with `containerId`. See
   `../../benchmark-diagrams/results/04-eraser/inventory-eraser.json` as a complete template.

2. Render:

   ```bash
   npx eraser-diagrams render diagram.json --chromium-path "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" -o diagram.png
   ```

3. **Read the warnings.** A nonexistent icon does not fail the render: it becomes a generic glyph and a
   `W_UNKNOWN_ICON` warning with a suggestion of a similar name. Fix it and run again.

4. Open the PNG and look for a connection label on top of a group title, and for a container
   too small for its content. Both are solved by adjusting `x`, `y` and `height`.

## Icon names

They are not guessable. There is no `aws-ecs`, `aws-sqs`, `aws-s3`, `argocd` or `aws-eks`. The
correct ones are `aws-elastic-container-service`, `aws-simple-queue-service`,
`aws-simple-storage-service`, `argo` and `aws-ec2`. These also work: `aws-rds`,
`aws-secrets-manager`, `aws-nat-gateway`, `aws-direct-connect`,
`aws-elastic-load-balancing`, `kubernetes`, `postgres`, `docker` and `user`.

To find a new name, render a throwaway JSON with the candidates and read the warnings
— it is faster than searching the catalog.
