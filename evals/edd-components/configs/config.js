// PromptFoo Configuration
// Auto-generated from goldset.md following EDD principles
// Generated: 2026-03-30T10:33:28Z

const path = require('path');

module.exports = {
  description: 'EDD Evaluation Suite - Binary Pass/Fail with Evaluation Pyramid',

  // EDD Principle IV: Evaluation Pyramid
  tests: [

    // ============================================
    // TIER 1: Fast Deterministic Checks (<30s)
    // ============================================

    // Security Baseline (Always Applied)
    {
      description: 'Security Baseline - PII Leakage',
      assert: [{
        type: 'python',
        value: './graders/check_pii_leakage.py',
      }],
      metadata: { tier: 1, type: 'security_baseline', priority: 'critical' }
    },

    {
      description: 'Security Baseline - Prompt Injection',
      assert: [{
        type: 'python',
        value: './graders/check_prompt_injection.py',
      }],
      metadata: { tier: 1, type: 'security_baseline', priority: 'critical' }
    },

    {
      description: 'Security Baseline - Hallucination Detection',
      assert: [{
        type: 'python',
        value: './graders/check_hallucination.py',
      }],
      metadata: { tier: 1, type: 'security_baseline', priority: 'critical' }
    },

    {
      description: 'Security Baseline - Misinformation Detection',
      assert: [{
        type: 'python',
        value: './graders/check_misinformation.py',
      }],
      metadata: { tier: 1, type: 'security_baseline', priority: 'critical' }
    },

    // Goldset Tier 1 Criteria
    {
      description: 'Regulatory Compliance Validation',
      assert: [{
        type: 'python',
        value: './graders/check_regulatory_compliance.py',
      }],
      metadata: {
        tier: 1,
        type: 'goldset_criterion',
        criterion: 'eval-001',
        failure_type: 'specification_failure'
      }
    },

    // ============================================
    // TIER 2: Goldset Semantic Evaluation (<5min)
    // ============================================

    {
      description: 'Context Adherence Validation',
      assert: [{
        type: 'python',
        value: './graders/check_context_adherence.py',
      }],
      metadata: {
        tier: 2,
        type: 'goldset_criterion',
        criterion: 'eval-002',
        failure_type: 'generalization_failure',
        evaluator_type: 'llm-judge'
      }
    }
  ],

  // EDD Principle II: Binary pass/fail outputs only
  outputPath: '../results/promptfoo_results.json',

  // EDD Principle V: Trajectory observability
  writeLatestResults: true,
  share: false,

  // EDD Principle IX: Test data versioning metadata
  metadata: {
    version: '1.0.0',
    generated: '2026-03-30T10:33:28Z',
    goldset_version: '1.0.0',
    edd_compliant: true,
    binary_only: true,
    evaluation_pyramid: true,
    tier1_sla: '30_seconds',
    tier2_sla: '5_minutes',

    // EDD Principle VIII: Failure type routing
    criteria_mapping: {
      'eval-001': { name: 'Regulatory Compliance', failure_type: 'specification_failure' },
      'eval-002': { name: 'Context Adherence', failure_type: 'generalization_failure' }
    }
  }
};
