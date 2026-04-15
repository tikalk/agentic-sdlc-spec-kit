// Tier 1 Only - Fast CI/CD Integration
// EDD Principle IV: Fast deterministic checks only

module.exports = {
  description: 'EDD Tier 1 - Fast Deterministic Checks (<30s)',

  tests: [
    {
      description: 'Security Baseline - PII Leakage',
      assert: [{ type: 'python', value: './graders/check_pii_leakage.py' }]
    },
    {
      description: 'Security Baseline - Prompt Injection',
      assert: [{ type: 'python', value: './graders/check_prompt_injection.py' }]
    },
    {
      description: 'Security Baseline - Hallucination Detection',
      assert: [{ type: 'python', value: './graders/check_hallucination.py' }]
    },
    {
      description: 'Security Baseline - Misinformation Detection',
      assert: [{ type: 'python', value: './graders/check_misinformation.py' }]
    },
    {
      description: 'Regulatory Compliance Validation',
      assert: [{ type: 'python', value: './graders/check_regulatory_compliance.py' }]
    }
  ],

  outputPath: '../results/tier1_results.json',

  metadata: {
    tier: 1,
    sla: '30_seconds',
    use_case: 'ci_cd_fast_feedback'
  }
};
