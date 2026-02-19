// PromptFoo configuration for Clarify Command tests
module.exports = {
  description: 'Clarify Command Quality Evaluation',

  // Rate limiting to avoid 429 errors
  evaluateOptions: {
    maxConcurrency: 1,
    delay: process.env.CI ? 15000 : 2000, // 15s in CI to avoid rate limiting, 2s locally
  },

  // Clarify prompt
  prompts: ['file://../prompts/clarify-prompt.txt'],

  // Configure LLM provider using OpenAI-compatible endpoint
  providers: [
    {
      id: `openai:chat:${process.env.LLM_MODEL || 'claude-sonnet-4-5-20250929'}`,
      label: `${process.env.LLM_MODEL || 'Sonnet 4.5'} (via AI API Gateway)`,
      config: {
        apiBaseUrl: process.env.LLM_BASE_URL,
        apiKey: process.env.LLM_AUTH_TOKEN,
        temperature: 0.3,
        max_tokens: 4000,
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
      // Strip any preamble/thinking before the actual content
      transform: 'output.replace(/^.*?(?=## 1\\.\\s+Ambiguity Analysis)/s, "").trim()',
    },
    assert: [
      { type: 'python', value: 'file://../graders/custom_graders.py:check_pii_leakage' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_prompt_injection' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_hallucination_signals' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_misinformation' },
    ],
  },

  tests: [
    // Test 1: Clarify identifies gaps in a deliberately vague spec
    {
      description: 'Clarify: Identifies ambiguities in a vague specification',
      vars: {
        user_input:
          'Build a notification system. It should be fast and support multiple channels. Users should be able to configure their preferences. The system needs to handle high volumes.',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Grade the clarification quality (0-1):\n' +
            '1. Does it identify that "fast" is vague and needs quantification?\n' +
            '2. Does it ask what "multiple channels" means (email, SMS, push, webhook)?\n' +
            '3. Does it question what "high volumes" means with specific numbers?\n' +
            '4. Does it ask about preference configuration scope (per-channel, per-event, schedules)?\n' +
            '5. Are questions specific and actionable (not generic)?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
        { type: 'icontains', value: 'clarification' },
      ],
    },

    // Test 2: Architect Clarify focuses on architectural concerns
    {
      description: 'Clarify: Focuses on architectural concerns for system-level spec',
      vars: {
        user_input:
          'We have an existing monolith handling 500 req/s. We want to add real-time features (live updates, presence indicators) and eventually support 50,000 concurrent users. The team has 3 backend developers. Current stack is Django + PostgreSQL.',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Grade the architectural focus of clarification questions (0-1):\n' +
            '1. Does it ask about the WebSocket/SSE approach for real-time (architecture decision)?\n' +
            '2. Does it question scaling strategy (horizontal vs vertical, breaking the monolith)?\n' +
            '3. Does it address data flow for real-time updates (pub/sub, polling, change data capture)?\n' +
            '4. Does it consider team size vs complexity (3 devs vs microservices risk)?\n' +
            '5. Does it focus on ARCHITECTURE concerns rather than feature details?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },
  ],
};
