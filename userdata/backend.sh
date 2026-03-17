#!/bin/bash
dnf update -y

# ─── Install Node.js 18 (AL2023 has it in its own repo) ─────────────────────────
dnf install -y nodejs npm

# ─── Create app directory ────────────────────────────────────────────────────────
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

npm init -y
npm install express

# ─── Create server.js ────────────────────────────────────────────────────────────
# ${full_name} is injected by Terraform's templatefile() at deploy time
cat > server.js << 'APPEOF'
const express = require("express");
const { execSync } = require("child_process");
const app = express();
const PORT = 3000;

function getMeta(path) {
  try {
    const token = execSync(
      'curl -s -X PUT "http://169.254.169.254/latest/api/token" ' +
      '-H "X-aws-ec2-metadata-token-ttl-seconds: 21600"'
    ).toString().trim();
    return execSync(
      `curl -s -H "X-aws-ec2-metadata-token: $${token}" ` +
      `http://169.254.169.254/latest/meta-data/$${path}`
    ).toString().trim();
  } catch (e) {
    return "unknown";
  }
}

app.get("/api/health", (req, res) => {
  res.json({
    status: "healthy",
    tier: "backend",
    name: "${full_name}",
    instanceId: getMeta("instance-id"),
    availabilityZone: getMeta("placement/availability-zone"),
    timestamp: new Date().toISOString(),
  });
});

app.get("/api/data", (req, res) => {
  res.json({
    message: "Hello from the Backend Tier — ${full_name}!",
    instanceId: getMeta("instance-id"),
    availabilityZone: getMeta("placement/availability-zone"),
    timestamp: new Date().toISOString(),
    items: [
      { id: 1, name: "VPC",  description: "Virtual Private Cloud" },
      { id: 2, name: "ALB",  description: "Application Load Balancer" },
      { id: 3, name: "ASG",  description: "Auto Scaling Group" },
      { id: 4, name: "IAM",  description: "Identity and Access Management" },
      { id: 5, name: "SSM",  description: "Systems Manager Parameter Store" },
    ],
  });
});

app.listen(PORT, () => console.log(`Backend API running on port $${PORT}`));
APPEOF

chown -R ec2-user:ec2-user /home/ec2-user/app
node /home/ec2-user/app/server.js &
