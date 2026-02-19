// PromptFoo configuration for Trace Validation tests
module.exports = {
  description: 'Trace Template Quality Evaluation',

  // Rate limiting to avoid 429 errors
  concurrency: 1,
  delay: process.env.CI ? 15000 : 2000, // 15s in CI to avoid rate limiting, 2s locally

  // Trace prompt
  prompts: ['file://../prompts/trace-prompt.txt'],

  // Configure LLM provider using OpenAI-compatible endpoint
  providers: [
    {
      id: `openai:chat:${process.env.LLM_MODEL || 'claude-sonnet-4-5-20250929'}`,
      label: `${process.env.LLM_MODEL || 'Sonnet 4.5'} (via AI API Gateway)`,
      config: {
        apiBaseUrl: process.env.LLM_BASE_URL,
        apiKey: process.env.LLM_AUTH_TOKEN,
        temperature: 0.7,
        max_tokens: 5000,
      },
      env: {
        OPENAI_API_KEY: process.env.LLM_AUTH_TOKEN,
        OPENAI_BASE_URL: process.env.LLM_BASE_URL,
      },
    },
  ],

  defaultTest: {
    options: {
      provider: `openai:chat:${process.env.LLM_MODEL || 'claude-sonnet-4-5-20250929'}`,
    },
    assert: [
      { type: 'python', value: 'file://../graders/custom_graders.py:check_pii_leakage' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_prompt_injection' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_hallucination_signals' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_misinformation' },
    ],
  },

  tests: [
    // Test 1: Trace Structure Completeness
    {
      description: 'Trace: Generated trace has all required sections',
      vars: {
        user_input:
          'Create a session trace for implementing a user authentication feature with JWT tokens, password hashing with bcrypt, refresh token rotation, and role-based access control. The implementation used TDD with pytest and achieved 95% code coverage.',
      },
      assert: [
        { type: 'icontains', value: 'summary' },
        { type: 'icontains', value: 'decision' },
        { type: 'icontains', value: 'artifact' },
        {
          type: 'llm-rubric',
          value:
            'Grade the trace document completeness (0-1):\n' +
            '1. Does it have a Summary with Problem, Key Decisions, and Final Solution?\n' +
            '2. Does it document implementation steps chronologically?\n' +
            '3. Does it include a decisions log with rationale for each decision?\n' +
            '4. Does it list quality gates (tests, coverage, security)?\n' +
            '5. Does it include artifacts produced (files, tests, configs)?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },

    // Test 2: Trace Decision Quality
    {
      description: 'Trace: Decisions have proper rationale and alternatives',
      vars: {
        user_input:
          'Create a session trace for building a real-time notification system. The team chose WebSockets over SSE for bidirectional communication, Redis pub/sub for message distribution, and PostgreSQL for persistence. Implementation faced challenges with connection scaling at 5000+ concurrent users.',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Grade the decision documentation quality (0-1):\n' +
            '1. Is each decision documented with context (why it was needed)?\n' +
            '2. Are alternatives mentioned (WebSocket vs SSE, Redis vs alternatives)?\n' +
            '3. Is the rationale for each choice explained?\n' +
            '4. Are challenges and their resolutions documented?\n' +
            '5. Are lessons learned included?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },
  ],
};