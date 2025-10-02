## Running the supply‑chain pipeline

```bash
make clean
make vendor-verify
make lock
make sbom
make audit
make split-repos
```

### Prerequisites

**macOS**
```bash
brew install jq python@3.11
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

**Ubuntu**
```bash
sudo apt-get update
sudo apt-get install -y jq python3
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

**Windows** (PowerShell)
```powershell
winget install 0x7B.Syft
winget install 0x7B.Grype
winget install Aqua.Trivy
```

All tools install to `/usr/local/bin` or `$HOME/.local/bin` and must be in your `PATH`.
