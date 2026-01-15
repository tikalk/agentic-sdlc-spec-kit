// PromptFoo configuration for Plan Template tests only
module.exports = {
  description: 'Plan Template Quality Evaluation',

  // Plan prompt only
  prompts: ['file://../prompts/plan-prompt.txt'],

  // Configure LLM provider using OpenAI-compatible endpoint
  providers: [
    {
      id: `openai:chat:${process.env.LLM_MODEL || 'claude-sonnet-4-5-20250929'}`,
      label: `Claude ${process.env.LLM_MODEL || 'Sonnet 4.5'} (via AI API Gateway)`,
      config: {
        apiBaseUrl: process.env.LLM_BASE_URL,
        apiKey: process.env.LLM_API_KEY,
        temperature: 0.7,
        max_tokens: 4000,
      },
      env: {
        OPENAI_API_KEY: process.env.LLM_API_KEY,
        OPENAI_BASE_URL: process.env.LLM_BASE_URL,
      },
    },
  ],

  defaultTest: {
    options: {
      provider: `openai:chat:${process.env.LLM_MODEL || 'claude-sonnet-4-5-20250929'}`,
    },
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
  ],
};