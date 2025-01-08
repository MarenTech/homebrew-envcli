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
      # First verify Node.js is available before proceeding
      if !Utils.safe_popen_read("which", "node").present?
        odie "Node.js is required but not found. Please install Node.js first."
      end
      
      # Extract and verify the package contents
      system "tar", "xf", cached_download, "-C", buildpath
      
      # Verify package.json exists after extraction
      unless File.exist?("package.json")
        odie "package.json not found in the archive. The archive may be corrupted."
      end
      
      # Install dependencies with error checking
      system "npm", "install", "--production"
      unless $?.success?
        odie "Failed to install npm dependencies. Please ensure you have write permissions and a stable internet connection."
      end
      
      # Move package contents to libexec with error checking
      libexec.install Dir["*"]
      libexec.install Dir["node_modules"]
      
      # Ensure config directory exists with proper permissions
      (var/"envcli").mkpath
      chmod 0755, var/"envcli"
      
      # Create the executable script
      (bin/"envcli").write <<~EOS
        #!/bin/bash
        if ! command -v node >/dev/null 2>&1; then
          echo "Error: Node.js is required but not installed. Please install Node.js first."
          exit 1
        fi
        
        # Ensure the required directories exist
        if [ ! -d "#{libexec}" ]; then
          echo "Error: Installation directory not found. Please reinstall the package."
          exit 1
        fi
        
        if [ ! -d "#{var}/envcli" ]; then
          mkdir -p "#{var}/envcli"
          chmod 755 "#{var}/envcli"
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
        Configuration will be stored in: #{var}/envcli
        
        If you experience any issues:
        1. Ensure Node.js is installed and in your PATH
        2. Check permissions in #{var}/envcli
        3. Verify your npm installation is working correctly
      EOS
    end
  
    test do
      # Verify the binary exists and is executable
      assert_predicate bin/"envcli", :executable?
      
      # Test basic functionality if Node.js is available
      if system("which node >/dev/null 2>&1")
        assert_match "envcli", shell_output("#{bin}/envcli about")
        assert_match version.to_s, shell_output("#{bin}/envcli version")
      end
    end
  end