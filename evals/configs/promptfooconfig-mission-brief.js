// PromptFoo configuration for Mission Brief tests
// Tests the /adlc.spec.specify command's Mission Brief enforcement
module.exports = {
  description: 'Mission Brief Enforcement Evaluation',

  // Rate limiting to avoid 429 errors
  evaluateOptions: {
    maxConcurrency: 1,
    delay: process.env.CI ? 15000 : 5000,
  },

  // Mission Brief prompt
  prompts: ['file://../prompts/mission-brief-prompt.txt'],

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
    // Test 1: Mission Brief Completeness - Substantial Input
    {
      description: 'Mission Brief: Extracts complete Mission Brief from detailed input',
      vars: {
        user_input:
          'Build a user authentication system with email/password login, password reset via email, and session management. Users should be able to stay logged in for 30 days. The system must support 10,000 concurrent users and comply with GDPR for European users.',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_mission_brief_completeness' },
        { type: 'icontains', value: 'goal' },
        { type: 'icontains', value: 'success criteria' },
        { type: 'icontains', value: 'demo sentence' },
        { type: 'icontains', value: 'proceed with this mission brief' },
      ],
    },

    // Test 2: Mission Brief Quality - Goal Extraction
    {
      description: 'Mission Brief: Goal is concise and captures core purpose',
      vars: {
        user_input:
          'Create a dashboard where admins can view real-time analytics including user signups, active sessions, revenue metrics, and system health. The dashboard should update every 5 seconds and support drill-down into individual metrics.',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_mission_brief_quality' },
        {
          type: 'llm-rubric',
          value:
            'Grade the Mission Brief Goal quality (0-1):\n' +
            '1. Is the Goal a single sentence?\n' +
            '2. Does it capture the core purpose (admin analytics dashboard)?\n' +
            '3. Is it technology-agnostic (no frameworks, databases)?\n' +
            '4. Is it measurable/achievable?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },

    // Test 3: Mission Brief - Constraint Extraction
    {
      description: 'Mission Brief: Extracts constraints from requirements',
      vars: {
        user_input:
          'Build a payment processing integration for our e-commerce platform. Must comply with PCI-DSS, support credit cards and PayPal, process transactions under 3 seconds, and work with our existing Django backend. Budget is limited so we need to use Stripe as the payment provider.',
      },
      assert: [
        { type: 'icontains', value: 'constraint' },
        { type: 'icontains', value: 'pci' },
        {
          type: 'llm-rubric',
          value:
            'Check if the Mission Brief Constraints section includes:\n' +
            '1. PCI-DSS compliance requirement\n' +
            '2. Performance constraint (3 second processing)\n' +
            '3. Technical constraint (Django backend integration)\n' +
            '4. Budget/provider constraint (Stripe)\n' +
            'Return 1.0 if all constraints captured, 0.5 if some, 0.0 if none.',
          threshold: 0.7,
        },
      ],
    },

    // Test 4: Mission Brief - Demo Sentence Observable
    {
      description: 'Mission Brief: Demo Sentence is observable and concrete',
      vars: {
        user_input:
          'Add a file upload feature to the project management app. Users should be able to upload PDF, Word, and image files up to 25MB. Files should be attached to tasks and downloadable by team members.',
      },
      assert: [
        { type: 'icontains', value: 'demo sentence' },
        { type: 'icontains', value: 'user can' },
        {
          type: 'llm-rubric',
          value:
            'Grade the Demo Sentence quality (0-1):\n' +
            '1. Does it describe an observable user action (not just "have file upload")?\n' +
            '2. Is it concrete and specific (mentions uploading/downloading files)?\n' +
            '3. Can a human verify this outcome (e.g., "upload a PDF and download it")?\n' +
            '4. Does it avoid implementation details?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },

    // Test 5: Mission Brief - Minimal Input Triggers Questions
    {
      description: 'Mission Brief: Minimal input triggers clarifying questions',
      vars: {
        user_input: 'Add search',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Check if the response asks clarifying questions for the minimal input:\n' +
            '1. Does it ask about the goal/purpose of the search feature?\n' +
            '2. Does it ask about success criteria or expected outcomes?\n' +
            '3. Does it ask about constraints or requirements?\n' +
            '4. Does it NOT skip to creating a spec without gathering more info?\n' +
            'Return 1.0 if proper questions asked, 0.0 if it proceeds without clarification.',
          threshold: 0.7,
        },
      ],
    },

    // Test 6: Mission Brief - Approval Prompt Present
    {
      description: 'Mission Brief: Always includes approval prompt',
      vars: {
        user_input:
          'Create a notification system that sends email, SMS, and push notifications. Users can configure their preferences per notification type. Support for templated messages with variable substitution.',
      },
      assert: [
        { type: 'icontains', value: 'proceed' },
        { type: 'icontains-any', value: ['yes / no', 'yes/no', '(yes', 'yes, no'] },
        {
          type: 'llm-rubric',
          value:
            'Check if the response includes a clear approval request:\n' +
            '1. Is there a "Proceed with this Mission Brief?" question?\n' +
            '2. Are options provided (yes/no/adjust or similar)?\n' +
            '3. Does the flow indicate waiting for user response before continuing?\n' +
            'Return 1.0 if proper approval flow, 0.0 if missing.',
          threshold: 0.8,
        },
      ],
    },
  ],
};
