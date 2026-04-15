// EDD Integration Wrapper Class
// evals/edd-components/edd-integration.js
const fs = require('fs');
const path = require('path');

class EDDIntegration {
  constructor(existingConfig) {
    this.config = existingConfig;
    this.eddEnhanced = false;
  }

  // Add EDD security baseline to any config
  addSecurityBaseline() {
    const securityTests = this.loadEDDSecurityTests();
    this.config.tests = [...this.config.tests, ...securityTests];
    return this;
  }

  // Enhance existing tests with EDD metadata
  enhanceWithEDD() {
    this.config.tests = this.config.tests.map((test, index) => ({
      ...test,
      metadata: {
        ...test.metadata,
        edd_enhanced: true,
        tier: this.classifyTier(test),
        failure_routing: this.determineFailureRouting(test)
      }
    }));

    return this;
  }

  // Add EDD-compliant post-processing
  addFailureRouting() {
    this.config.postprocess = {
      ...this.config.postprocess,
      eddFailureRouting: true,
      routeFailures: this.routeFailures.bind(this)
    };

    return this;
  }

  // Return enhanced config
  build() {
    this.config.metadata = {
      ...this.config.metadata,
      edd_enhanced: true,
      edd_version: '1.0.0',
      original_system_preserved: true
    };

    return this.config;
  }

  // Helper methods
  loadEDDSecurityTests() {
    return [
      {
        description: 'EDD Security - PII Leakage Detection',
        assert: [{
          type: 'python',
          value: './graders/check_pii_leakage.py'
        }],
        metadata: {
          tier: 1,
          type: 'edd_security_baseline',
          edd_principle: 'IV_evaluation_pyramid'
        }
      },
      {
        description: 'EDD Security - Prompt Injection Detection',
        assert: [{
          type: 'python',
          value: './graders/check_prompt_injection.py'
        }],
        metadata: {
          tier: 1,
          type: 'edd_security_baseline',
          edd_principle: 'IV_evaluation_pyramid'
        }
      },
      {
        description: 'EDD Security - Hallucination Detection',
        assert: [{
          type: 'python',
          value: './graders/check_hallucination.py'
        }],
        metadata: {
          tier: 1,
          type: 'edd_security_baseline',
          edd_principle: 'IV_evaluation_pyramid'
        }
      },
      {
        description: 'EDD Security - Misinformation Detection',
        assert: [{
          type: 'python',
          value: './graders/check_misinformation.py'
        }],
        metadata: {
          tier: 1,
          type: 'edd_security_baseline',
          edd_principle: 'IV_evaluation_pyramid'
        }
      }
    ];
  }

  classifyTier(test) {
    const tier1_patterns = [
      'syntax', 'structure', 'format', 'required_fields',
      'security_baseline', 'basic_validation', 'icontains',
      'not-icontains', 'regression'
    ];
    const testName = test.description || '';
    const isFast = tier1_patterns.some(pattern =>
      testName.toLowerCase().includes(pattern)
    );
    return isFast ? 1 : 2;
  }

  determineFailureRouting(test) {
    const specPatterns = ['spec', 'requirement', 'format', 'structure', 'regression'];
    const testName = test.description || '';
    const isSpecFailure = specPatterns.some(pattern =>
      testName.toLowerCase().includes(pattern)
    );

    return {
      failure_type: isSpecFailure ? 'specification_failure' : 'generalization_failure',
      action: isSpecFailure ? 'fix_directive' : 'build_evaluator'
    };
  }

  routeFailures(results) {
    // Implementation for failure routing based on test results
    // This routes failures to appropriate directories for EDD Principle VIII
    const routedResults = results.map(result => {
      if (!result.pass) {
        const routing = this.determineFailureRouting(result);
        const riskScore = this.calculateRiskScore(result);

        return {
          ...result,
          edd_routing: {
            ...routing,
            risk_score: riskScore,
            routed_at: new Date().toISOString()
          }
        };
      }
      return result;
    });

    // Generate failure routing summary
    const failures = routedResults.filter(r => !r.pass);
    if (failures.length > 0) {
      this.generateFailureRoutingSummary(failures);
    }

    return routedResults;
  }

  calculateRiskScore(result) {
    let risk = 0.0;

    // Security-related failures are high risk
    const description = result.description || '';
    const securityPatterns = ['security', 'pii', 'hallucination', 'injection', 'misinformation'];
    if (securityPatterns.some(pattern => description.toLowerCase().includes(pattern))) {
      risk += 0.5;
    }

    // Very low scores indicate high risk
    const score = result.score || 0;
    if (score < 0.3) risk += 0.4;
    else if (score < 0.6) risk += 0.2;

    return Math.min(risk, 1.0);
  }

  generateFailureRoutingSummary(failures) {
    const summary = {
      timestamp: new Date().toISOString(),
      total_failures: failures.length,
      specification_failures: failures.filter(f =>
        f.edd_routing?.failure_type === 'specification_failure'
      ).length,
      generalization_failures: failures.filter(f =>
        f.edd_routing?.failure_type === 'generalization_failure'
      ).length,
      high_risk_failures: failures.filter(f =>
        f.edd_routing?.risk_score >= 0.8
      ).length
    };

    console.log('\n📊 EDD Failure Routing Summary:');
    console.log(`   Total failures: ${summary.total_failures}`);
    console.log(`   → Specification failures: ${summary.specification_failures}`);
    console.log(`   → Generalization failures: ${summary.generalization_failures}`);
    console.log(`   → High-risk failures: ${summary.high_risk_failures}`);

    return summary;
  }
}

// Usage example for external teams:
// const { EDDIntegration } = require('./edd-components/edd-integration');
// const enhancedConfig = new EDDIntegration(yourProjectConfig)
//   .addSecurityBaseline()
//   .enhanceWithEDD()
//   .addFailureRouting()
//   .build();
//
// module.exports = enhancedConfig;

module.exports = { EDDIntegration };