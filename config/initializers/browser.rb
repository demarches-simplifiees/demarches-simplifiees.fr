Browser.modern_rules.clear
Browser.modern_rules << -> b { b.chrome? && b.version.to_i >= 40 }
Browser.modern_rules << -> b { b.ie?([">=11"]) }
Browser.modern_rules << -> b { b.edge? }
Browser.modern_rules << -> b { b.firefox? && b.version.to_i >= 45 }
Browser.modern_rules << -> b { b.opera? && b.version.to_i >= 19 }
Browser.modern_rules << -> b { b.safari? && b.version.to_i >= 8 }
