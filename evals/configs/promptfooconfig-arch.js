// PromptFoo configuration for Architecture Template tests
module.exports = {
  description: 'Architecture Template Quality Evaluation',

  // Rate limiting to avoid 429 errors
  maxConcurrency: 1,
  delay: 2000, // 2 second delay between tests

  // Architecture prompt
  prompts: ['file://../prompts/arch-prompt.txt'],

  // Configure LLM provider using OpenAI-compatible endpoint
  providers: [
    {
      id: `openai:chat:${process.env.LLM_MODEL || 'claude-sonnet-4-5-20250929'}`,
      label: `${process.env.LLM_MODEL || 'Sonnet 4.5'} (via AI API Gateway)`,
      config: {
        apiBaseUrl: process.env.LLM_BASE_URL,
        apiKey: process.env.LLM_AUTH_TOKEN,
        temperature: 0.7,
        max_tokens: 6000,
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
  },

  tests: [
    // Test 1: Architecture Init Quality - Structure Validation
    {
      description: 'Architecture: Init produces valid Rozanski & Woods structure',
      vars: {
        user_input:
          'Create an architecture description for an e-commerce platform with a web frontend, REST API backend, PostgreSQL database, and Redis cache. The system handles user authentication, product catalog, shopping cart, and order processing.',
      },
      assert: [
        { type: 'icontains', value: 'context view' },
        { type: 'icontains', value: 'functional view' },
        { type: 'icontains', value: 'deployment view' },
        { type: 'icontains', value: 'stakeholder' },
        {
          type: 'python',
          value: 'file://../graders/custom_graders.py:check_arch_structure',
        },
      ],
    },

    // Test 2: Blackbox Context View
    {
      description: 'Architecture: Context View enforces blackbox system representation',
      vars: {
        user_input:
          'Create an architecture description for a SaaS project management tool that integrates with GitHub, Slack, and Google Calendar. Users access it via web browser. An admin manages team settings.',
      },
      assert: [
        {
          type: 'python',
          value: 'file://../graders/custom_graders.py:check_blackbox_context_view',
        },
        {
          type: 'llm-rubric',
          value:
            'Check if the Context View section treats the system as a single blackbox.\n' +
            'The Context View should:\n' +
            '1. Show the system as ONE unified node (not broken into internal services)\n' +
            '2. Show external actors (users, admins) interacting with the system\n' +
            '3. Show external systems (GitHub, Slack, Google Calendar) as separate nodes\n' +
            '4. NOT show internal databases, caches, queues, or microservices in this view\n' +
            'Return 1.0 if blackbox constraint is followed, 0.5 if partially, 0.0 if internal details are exposed.',
          threshold: 0.7,
        },
      ],
    },

    // Test 3: Architecture Simplicity for Simple Systems
    {
      description: 'Architecture: Simple app gets simple architecture (no over-engineering)',
      vars: {
        user_input:
          'Create an architecture description for a simple personal blog with basic CRUD for posts, a SQLite database, and static file serving. Single developer, no team.',
      },
      assert: [
        {
          type: 'python',
          value: 'file://../graders/custom_graders.py:check_arch_simplicity',
        },
        {
          type: 'llm-rubric',
          value:
            'Is the architecture appropriately simple for a personal blog?\n' +
            'Check for:\n' +
            '- No microservices architecture for a blog\n' +
            '- No Kubernetes or complex orchestration\n' +
            '- No message queues or event sourcing\n' +
            '- Simple deployment (single server or basic hosting)\n' +
            '- Monolith or simple client-server is appropriate\n' +
            'Return 1.0 if appropriately simple, 0.5 if somewhat over-engineered, 0.0 if heavily over-engineered.',
          threshold: 0.7,
        },
      ],
    },

    // Test 4: ADR Quality
    {
      description: 'Architecture: ADRs follow template structure with required sections',
      vars: {
        user_input:
          'Create an architecture description for a real-time chat application with WebSocket support, message persistence, user presence tracking, and file sharing. The system must handle 10,000 concurrent users.',
      },
      assert: [
        { type: 'icontains', value: 'adr' },
        {
          type: 'python',
          value: 'file://../graders/custom_graders.py:check_adr_quality',
        },
        {
          type: 'llm-rubric',
          value:
            'Grade the ADR quality in this architecture document (0-1):\n' +
            '1. Does each ADR have a clear Status (Proposed/Accepted/Deprecated/Discovered)?\n' +
            '2. Does each ADR have a Context section explaining why the decision was needed?\n' +
            '3. Does each ADR have a clear Decision statement?\n' +
            '4. Does each ADR document Consequences (positive, negative, risks)?\n' +
            '5. Are alternatives documented with neutral trade-offs (not "rejected because")?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },
  ],
};
