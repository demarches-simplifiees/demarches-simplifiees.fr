# See .browserslistrc
Browser.modern_rules.clear
Browser.modern_rules << -> b { b.chrome? && b.version.to_i >= 50 && !b.platform.ios? }
Browser.modern_rules << -> b { b.edge? && b.version.to_i >= 14 && !b.compatibility_view? }
Browser.modern_rules << -> b { b.firefox? && b.version.to_i >= 50 && !b.platform.ios? }
Browser.modern_rules << -> b { b.opera? && b.version.to_i >= 40 }
Browser.modern_rules << -> b { b.safari? && b.version.to_i >= 8 }
Browser.modern_rules << -> b { b.platform.ios? && b.platform.version.to_i >= 8 }
