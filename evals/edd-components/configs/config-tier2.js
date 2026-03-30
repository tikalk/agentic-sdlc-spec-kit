// Tier 2 Only - Semantic Evaluation for Merge Gates
// EDD Principle IV: Goldset LLM judges

module.exports = {
  description: 'EDD Tier 2 - Goldset Semantic Evaluation (<5min)',

  tests: [
    {
      description: 'Context Adherence Validation',
      assert: [{ type: 'python', value: './graders/check_context_adherence.py' }]
    }
  ],

  outputPath: '../results/tier2_results.json',

  metadata: {
    tier: 2,
    sla: '5_minutes',
    use_case: 'merge_gate_validation'
  }
};
