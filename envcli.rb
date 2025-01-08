class Envcli < Formula
    desc "A CLI tool for managing environment variables"
    homepage "https://github.com/MarenTech/envcli"
    url "https://github.com/MarenTech/envcli/releases/download/v1.0.1/envcli-1.0.1.tgz"
    sha256 "8656ac09e094ba446bf1252f81b1c3814a72d840842cdfd56d2b493dd0282d2f"
    license "ISC"
  
    livecheck do
      url :stable
      strategy :github_latest
    end
  
    def install
      # Extract the package contents
      system "tar", "xf", cached_download, "-C", buildpath
      
      # Use the full path to npm
      npm = which("npm") || "/usr/local/bin/npm"
      if !npm.exist?
        odie "npm is required but not found. Please install Node.js first."
      end
      
      # Install dependencies using the full npm path
      system npm, "install", "--production"
      
      # Move package contents to libexec
      libexec.install Dir["*"]
      libexec.install Dir["node_modules"]
      
      # Ensure config directory exists
      (var/"envcli").mkpath
      
      # Create bin stubs with environment variables
      (bin/"envcli").write <<~EOS
        #!/bin/bash
        if ! command -v node >/dev/null 2>&1; then
          echo "Error: Node.js is required but not installed. Please install Node.js first."
          exit 1
        fi
        export NODE_PATH="#{libexec}/node_modules"
        export ENVCLI_CONFIG_DIR="#{var}/envcli"
        exec "$(command -v node)" "#{libexec}/index.js" "$@"
      EOS
      
      chmod 0755, bin/"envcli"
    end
  
    def caveats
      <<~EOS
        envcli requires Node.js to be installed.
        If you haven't installed Node.js yet, please install it first.
      EOS
    end
  
    def post_install
      (var/"envcli").mkpath
      chmod 0755, var/"envcli"
    end
  
    test do
      assert_match "envcli", shell_output("#{bin}/envcli about")
      assert_match version.to_s, shell_output("#{bin}/envcli version")
    end
  end