class Envcli < Formula
    desc "A CLI tool for managing environment variables"
    homepage "https://github.com/MarenTech/envcli"
    url "https://github.com/MarenTech/envcli/releases/download/v1.0.1/envcli-1.0.1.tgz"
    sha256 "8656ac09e094ba446bf1252f81b1c3814a72d840842cdfd56d2b493dd0282d2f"
    license "ISC"
  
    depends_on "node"
  
    livecheck do
      url :stable
      strategy :github_latest
    end
  
    def install
      node_version = Utils.popen_read("node -v").strip rescue nil
      if node_version
        ohai "Using existing Node.js installation: #{node_version}"
      end
      
      # Extract the package contents
      system "tar", "xf", cached_download, "-C", buildpath
      
      # Create package.json if it doesn't exist
      system "npm", "init", "-y" unless File.exist? "package.json"
      
      # Install all dependencies
      system "npm", "install", "commander@12.1.0"
      system "npm", "install", "chalk@4.1.2"
      system "npm", "install", "figlet@1.8.0"
      system "npm", "install", "inquirer@9.2.12"
      system "npm", "install", "node-fetch@3.3.2"
      
      # Install all dependencies from package.json if it exists
      system "npm", "install", "--production" if File.exist? "package.json"
      
      # Move package contents to libexec
      libexec.install Dir["*"]
      libexec.install Dir["node_modules"]
      
      # Ensure config directory exists
      (var/"envcli").mkpath
      
      # Create bin stubs with environment variables
      (bin/"envcli").write <<~EOS
        #!/bin/bash
        export NODE_PATH="#{libexec}/node_modules"
        export ENVCLI_CONFIG_DIR="#{var}/envcli"
        exec "#{Formula["node"].opt_bin}/node" "#{libexec}/index.js" "$@"
      EOS
      
      # Make the bin stub executable
      chmod 0755, bin/"envcli"
    end
  
    def post_install
      # Ensure config directory has correct permissions
      (var/"envcli").mkpath
      chmod 0755, var/"envcli"
    end
  
    test do
      assert_match "envcli", shell_output("#{bin}/envcli about")
      assert_match version.to_s, shell_output("#{bin}/envcli version")
    end
  end