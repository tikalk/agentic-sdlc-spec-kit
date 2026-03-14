// PromptFoo configuration for Spec Template tests only
module.exports = {
  description: 'Spec Template Quality Evaluation',

  // Rate limiting to avoid 429 errors
  evaluateOptions: {
    maxConcurrency: 1,
    delay: process.env.CI ? 15000 : 5000, // 15s in CI to avoid rate limiting, 5s locally
  },

  // Spec prompt only
  prompts: ['file://../prompts/spec-prompt.txt'],

  // Configure LLM provider using OpenAI-compatible endpoint
  providers: [
    {
      id: `openai:chat:${process.env.LLM_MODEL || 'claude-sonnet-4-5-20250929'}`,
      label: `${process.env.LLM_MODEL || 'Sonnet 4.5'} (via AI API Gateway)`,
      config: {
        apiBaseUrl: process.env.LLM_BASE_URL,
        apiKey: process.env.LLM_AUTH_TOKEN,
        temperature: 0.7,
        max_tokens: 8000,  // Increased to allow full spec with all sections including Edge Cases
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
    // Test 1: Basic Spec Structure
    {
      description: 'Spec Template: Basic CRUD app - Structure validation',
      vars: {
        user_input:
          'Build a task management app where users can create, edit, delete, and view tasks. Each task has a title, description, due date, and priority (low/medium/high).',
      },
      assert: [
        { type: 'icontains', value: 'overview' },
        { type: 'icontains', value: 'functional requirements' },
        { type: 'icontains', value: 'user stor' },
        { type: 'icontains', value: 'non-functional' },
        { type: 'icontains', value: 'edge case' },
      ],
    },

    // Test 2: No Premature Tech Stack
    {
      description: 'Spec Template: Should not include tech stack details',
      vars: {
        user_input: 'Build a REST API for managing user profiles with CRUD operations',
      },
      assert: [
        { type: 'not-icontains', value: 'React' },
        { type: 'not-icontains', value: 'Node.js' },
        { type: 'not-icontains', value: 'Express' },
        { type: 'not-icontains', value: 'MongoDB' },
        {
          type: 'llm-rubric',
          value:
            'Check if this specification avoids technical implementation details.\nIt should focus on WHAT needs to be built, not HOW to build it.\nReturn 1.0 if no tech stack is mentioned, 0.5 if some mentioned, 0.0 if heavy tech details.',
          threshold: 0.8,
        },
      ],
    },

    // Test 3: Quality - User Stories
    {
      description: 'Spec Template: Has clear user stories with acceptance criteria',
      vars: {
        user_input: 'Create an authentication system with email/password login and social OAuth',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Grade the specification on user story quality (0-1):\n1. Are there 5+ user stories?\n2. Do stories follow "As a [role], I want [feature], so that [benefit]" format?\n3. Does each story have clear acceptance criteria?\n4. Are the criteria measurable and testable?\nReturn average score 0-1.',
          threshold: 0.75,
        },
      ],
    },

    // Test 4: Clarity - No Vague Terms
    {
      description: 'Spec Template: Flags vague requirements',
      vars: {
        user_input: 'Build a fast, scalable, user-friendly dashboard with good performance',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Check if vague terms like "fast", "scalable", "user-friendly", "good performance"\nare either:\n1. Quantified with specific metrics (e.g., "response time < 200ms")\n2. Marked with [NEEDS CLARIFICATION] or similar flags\n\nReturn 1.0 if all vague terms are handled properly, 0.0 if none are.',
          threshold: 0.7,
        },
      ],
    },

    // Test 5: Security Requirements
    {
      description: 'Spec Template: Security-critical features include security requirements',
      vars: {
        user_input: 'Create a payment processing system with credit card handling and transaction history',
      },
      assert: [
        { type: 'icontains', value: 'security' },
        { type: 'python', value: 'file://../graders/custom_graders.py:check_security_completeness' },
      ],
    },

    // Test 6: Edge Cases Coverage
    {
      description: 'Spec Template: Includes edge cases and error scenarios',
      vars: {
        user_input: 'Build a file upload system supporting multiple file types up to 100MB',
      },
      assert: [
        { type: 'icontains', value: 'edge case' },
        // Using Python grader instead of LLM rubric for more reliable results
        { type: 'python', value: 'file://../graders/custom_graders.py:check_edge_cases_coverage' },
      ],
    },

    // Test 9: Completeness Score
    {
      description: 'Spec Template: E-commerce checkout has comprehensive requirements',
      vars: {
        user_input: 'Build an e-commerce checkout flow with cart, payment, and order confirmation',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Grade completeness (0-1):\n1. Are functional requirements complete? (cart operations, payment, confirmation)\n2. Are user stories covering main flows?\n3. Are non-functional requirements specified? (performance, security)\n4. Are edge cases identified? (payment failures, session timeout)\nReturn average score 0-1.',
          threshold: 0.75,
        },
      ],
    },

    // Test 10: Regression Test - Basic Structure
    {
      description: 'Regression: Spec template maintains required sections',
      vars: {
        user_input: 'Simple feature: Add a search bar to existing app',
      },
      assert: [
        { type: 'icontains', value: 'functional requirements' },
        { type: 'icontains', value: 'user stor' },
        {
          type: 'javascript',
          value: `
            // Count major sections (## or #)
            const sections = output.split(/^#{1,2} /gm).length - 1;
            return sections >= 4;
          `,
        },
      ],
    },

    // Test 11: Spec Command Regression (post /speckit → /spec rename)
    {
      description: 'Regression: Spec output quality maintained after rename',
      vars: {
        user_input:
          'Build a user notification preferences page where users can toggle email, SMS, and push notifications per event type (marketing, transactional, security alerts)',
      },
      assert: [
        { type: 'icontains', value: 'overview' },
        { type: 'icontains', value: 'functional requirements' },
        { type: 'icontains', value: 'user stor' },
        { type: 'icontains', value: 'non-functional' },
        { type: 'icontains', value: 'edge case' },
        {
          type: 'llm-rubric',
          value:
            'Grade the specification quality (0-1):\n' +
            '1. Does it cover all three notification channels (email, SMS, push)?\n' +
            '2. Does it address per-event-type configuration?\n' +
            '3. Are user stories specific to notification preferences?\n' +
            '4. Does it include edge cases (invalid toggle states, rate limits)?\n' +
            '5. Are non-functional requirements addressing notification delivery?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },

    // ========================================
    // FORK-SPECIFIC SECTION TESTS (agentic-sdlc preset)
    // ========================================

    // Test 12: Fork Sections - Goal, Demo Sentence, Boundary Map
    {
      description: 'Fork Sections: Includes Goal, Demo Sentence, Boundary Map',
      vars: {
        user_input:
          'Build a multi-tenant project management system where teams can create projects, assign tasks, and track progress. Projects should have separate workspaces with role-based access control.',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_fork_spec_sections' },
        { type: 'icontains', value: 'goal' },
        { type: 'icontains', value: 'demo sentence' },
      ],
    },

    // Test 13: Fork Sections - Boundary Map Structure
    {
      description: 'Fork Sections: Boundary Map has Produces and Consumes',
      vars: {
        user_input:
          'Create a user profile service that exposes user data to other services. It consumes authentication tokens from the auth service and produces user profile objects for the dashboard and notification services.',
      },
      assert: [
        { type: 'icontains', value: 'boundary' },
        { type: 'icontains', value: 'produces' },
        { type: 'icontains', value: 'consumes' },
        {
          type: 'llm-rubric',
          value:
            'Check if the Boundary Map section is complete:\n' +
            '1. Does it have a Produces subsection listing what the feature exports?\n' +
            '2. Does it have a Consumes subsection listing what the feature requires?\n' +
            '3. Are the artifacts described with types (Module, Endpoint, Type, etc.)?\n' +
            '4. Does it show the relationship to other features?\n' +
            'Return 1.0 if complete, 0.5 if partial, 0.0 if missing.',
          threshold: 0.6,
        },
      ],
    },

    // Test 14: Fork Sections - Constraints Extraction
    {
      description: 'Fork Sections: Constraints are extracted and documented',
      vars: {
        user_input:
          'Build an API rate limiter that enforces 100 requests per minute per user. Must integrate with Redis, support distributed deployments, and comply with our SLA of 99.9% uptime. Budget constraint: use open source only.',
      },
      assert: [
        { type: 'icontains', value: 'constraint' },
        {
          type: 'llm-rubric',
          value:
            'Check if the Constraints section captures the key limitations:\n' +
            '1. Rate limit constraint (100 req/min)?\n' +
            '2. Technical constraint (Redis integration)?\n' +
            '3. Deployment constraint (distributed)?\n' +
            '4. SLA/uptime constraint (99.9%)?\n' +
            '5. Budget constraint (open source)?\n' +
            'Return score based on how many constraints are captured.',
          threshold: 0.6,
        },
      ],
    },
  ],
};
