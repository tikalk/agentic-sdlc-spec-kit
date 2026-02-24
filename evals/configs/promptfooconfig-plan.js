// PromptFoo configuration for Plan Template tests only
module.exports = {
  description: 'Plan Template Quality Evaluation',

  // Rate limiting to avoid 429 errors
  evaluateOptions: {
    maxConcurrency: 1,
    delay: process.env.CI ? 15000 : 2000, // 15s in CI to avoid rate limiting, 2s locally
  },

  // Plan prompt only
  prompts: ['file://../prompts/plan-prompt.txt'],

  // Configure LLM provider using OpenAI-compatible endpoint
  providers: [
    {
      id: `openai:chat:${process.env.LLM_MODEL || 'claude-sonnet-4-5-20250929'}`,
      label: `${process.env.LLM_MODEL || 'Sonnet 4.5'} (via AI API Gateway)`,
      config: {
        apiBaseUrl: process.env.LLM_BASE_URL,
        apiKey: process.env.LLM_AUTH_TOKEN,
        temperature: 0.7,
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
    },
    assert: [
      { type: 'python', value: 'file://../graders/custom_graders.py:check_pii_leakage' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_prompt_injection' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_hallucination_signals' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_misinformation' },
    ],
  },

  tests: [
    // Test 7: Plan Template - Simplicity Gate
    {
      description: 'Plan Template: Simple app should have ≤3 projects',
      vars: {
        user_input: 'Plan a simple todo app with Node.js and SQLite',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_simplicity_gate' },
        // Note: Removed not-icontains checks - our custom grader is context-aware
        // and handles "no microservices" vs "use microservices" correctly
      ],
    },

    // Test 8: Plan Template - Constitution Compliance
    {
      description: 'Plan Template: No over-engineering for basic CRUD API',
      vars: {
        user_input: 'Plan a basic REST API for CRUD operations on a todo list',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_constitution_compliance' },
        {
          type: 'llm-rubric',
          value:
            'Is the architecture appropriately simple for a basic CRUD API?\nCheck for:\n- No unnecessary complexity (service mesh, event sourcing, CQRS)\n- No over-engineered infrastructure (Kubernetes for simple app)\n- Direct framework usage (no unnecessary wrappers)\nReturn 1.0 if appropriately simple, 0.0 if over-engineered.',
          threshold: 0.8,
        },
      ],
    },

    // Test 13: Constitution Template Completeness
    {
      description: 'Plan Template: Constitution-aligned plan references governance principles',
      vars: {
        user_input:
          'Plan a multi-tenant SaaS application with user isolation, shared infrastructure, and per-tenant customization. Must follow team constitution principles for simplicity and avoid over-engineering.',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Grade the plan for constitution awareness (0-1):\n' +
            '1. Does it respect simplicity principles (not over-engineer for the requirements)?\n' +
            '2. Does it avoid unnecessary abstraction layers?\n' +
            '3. Are technology choices justified by actual needs?\n' +
            '4. Is the project count appropriate (not split into too many services)?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
        { type: 'python', value: 'file://../graders/custom_graders.py:check_simplicity_gate' },
      ],
    },

    // Test 14: Plan with Architecture Integration
    {
      description: 'Plan Template: Plan references architecture when system is complex',
      vars: {
        user_input:
          'Plan an API gateway service that routes requests to 3 backend microservices, handles rate limiting, JWT validation, and request/response transformation. The system architecture uses a microservices pattern with PostgreSQL and Redis.',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Grade the plan for architecture awareness (0-1):\n' +
            '1. Does it acknowledge the existing microservices architecture?\n' +
            '2. Does it plan for integration with the 3 backend services?\n' +
            '3. Does it address cross-cutting concerns (rate limiting, auth)?\n' +
            '4. Is the deployment strategy consistent with the described architecture?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },
  ],
};
