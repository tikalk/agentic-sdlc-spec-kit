// PromptFoo combined configuration — all test suites
// Individual suite configs: promptfooconfig-{spec,plan,arch,ext,clarify,trace}.js
module.exports = {
  description: 'Spec-Kit Quality Evaluation — Full Suite',

  // Rate limiting to avoid 429 errors
  maxConcurrency: 1,
  delay: 2000, // 2 second delay between tests

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
    assert: [
      { type: 'python', value: 'file://../graders/custom_graders.py:check_pii_leakage' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_prompt_injection' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_hallucination_signals' },
      { type: 'python', value: 'file://../graders/custom_graders.py:check_misinformation' },
    ],
  },

  // ============================================================
  // FULL TEST SUITE (27 tests across 6 categories)
  // ============================================================
  tests: [
    // ========================================
    // SPEC TEMPLATE TESTS (10 tests)
    // ========================================

    // Test 1: Basic Spec Structure
    {
      description: 'Spec Template: Basic CRUD app - Structure validation',
      prompt: 'file://../prompts/spec-prompt.txt',
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
      prompt: 'file://../prompts/spec-prompt.txt',
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
      prompt: 'file://../prompts/spec-prompt.txt',
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
      prompt: 'file://../prompts/spec-prompt.txt',
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
      prompt: 'file://../prompts/spec-prompt.txt',
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
      prompt: 'file://../prompts/spec-prompt.txt',
      vars: {
        user_input: 'Build a file upload system supporting multiple file types up to 100MB',
      },
      assert: [
        { type: 'icontains', value: 'edge case' },
        { type: 'python', value: 'file://../graders/custom_graders.py:check_edge_cases_coverage' },
      ],
    },

    // Test 9: Completeness Score
    {
      description: 'Spec Template: E-commerce checkout has comprehensive requirements',
      prompt: 'file://../prompts/spec-prompt.txt',
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
      prompt: 'file://../prompts/spec-prompt.txt',
      vars: {
        user_input: 'Simple feature: Add a search bar to existing app',
      },
      assert: [
        { type: 'icontains', value: 'functional requirements' },
        { type: 'icontains', value: 'user stor' },
        {
          type: 'javascript',
          value: `
            const sections = output.split(/^#{1,2} /gm).length - 1;
            return sections >= 4;
          `,
        },
      ],
    },

    // Test 11: Spec Command Regression (post rename)
    {
      description: 'Regression: Spec output quality maintained after rename',
      prompt: 'file://../prompts/spec-prompt.txt',
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

    // Test 12: Build-mode Spec Quality
    {
      description: 'Spec Template: Build-mode produces lean, focused output',
      prompt: 'file://../prompts/spec-prompt.txt',
      vars: {
        user_input:
          'Build a simple health check endpoint that returns server status, uptime, and database connectivity. Build mode - minimal spec.',
      },
      assert: [
        { type: 'icontains', value: 'requirement' },
        {
          type: 'llm-rubric',
          value:
            'Grade if this is appropriately lean for a simple health check feature (0-1):\n' +
            '1. Is it concise (not overly verbose for a health check endpoint)?\n' +
            '2. Does it include core functional requirements (status, uptime, db connectivity)?\n' +
            '3. Does it have success criteria?\n' +
            '4. Does it AVOID unnecessary complexity for such a simple feature?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },

    // ========================================
    // PLAN TEMPLATE TESTS (4 tests)
    // ========================================

    // Test 7: Simplicity Gate
    {
      description: 'Plan Template: Simple app should have ≤3 projects',
      prompt: 'file://../prompts/plan-prompt.txt',
      vars: {
        user_input: 'Plan a simple todo app with Node.js and SQLite',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_simplicity_gate' },
      ],
    },

    // Test 8: Constitution Compliance
    {
      description: 'Plan Template: No over-engineering for basic CRUD API',
      prompt: 'file://../prompts/plan-prompt.txt',
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

    // Test 13: Constitution-Aligned Plan
    {
      description: 'Plan Template: Constitution-aligned plan references governance principles',
      prompt: 'file://../prompts/plan-prompt.txt',
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
      prompt: 'file://../prompts/plan-prompt.txt',
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

    // ========================================
    // ARCHITECTURE TEMPLATE TESTS (4 tests)
    // ========================================

    // Test 15: Architecture Init Quality
    {
      description: 'Architecture: Init produces valid Rozanski & Woods structure',
      prompt: 'file://../prompts/arch-prompt.txt',
      vars: {
        user_input:
          'Create an architecture description for an e-commerce platform with a web frontend, REST API backend, PostgreSQL database, and Redis cache. The system handles user authentication, product catalog, shopping cart, and order processing.',
      },
      assert: [
        { type: 'icontains', value: 'context view' },
        { type: 'icontains', value: 'functional view' },
        { type: 'icontains', value: 'deployment view' },
        { type: 'icontains', value: 'stakeholder' },
        { type: 'python', value: 'file://../graders/custom_graders.py:check_arch_structure' },
      ],
    },

    // Test 16: Blackbox Context View
    {
      description: 'Architecture: Context View enforces blackbox system representation',
      prompt: 'file://../prompts/arch-prompt.txt',
      vars: {
        user_input:
          'Create an architecture description for a SaaS project management tool that integrates with GitHub, Slack, and Google Calendar. Users access it via web browser. An admin manages team settings.',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_blackbox_context_view' },
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

    // Test 17: Architecture Simplicity
    {
      description: 'Architecture: Simple app gets simple architecture (no over-engineering)',
      prompt: 'file://../prompts/arch-prompt.txt',
      vars: {
        user_input:
          'Create an architecture description for a simple personal blog with basic CRUD for posts, a SQLite database, and static file serving. Single developer, no team.',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_arch_simplicity' },
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

    // Test 18: ADR Quality
    {
      description: 'Architecture: ADRs follow template structure with required sections',
      prompt: 'file://../prompts/arch-prompt.txt',
      vars: {
        user_input:
          'Create an architecture description for a real-time chat application with WebSocket support, message persistence, user presence tracking, and file sharing. The system must handle 10,000 concurrent users.',
      },
      assert: [
        { type: 'icontains', value: 'adr' },
        { type: 'python', value: 'file://../graders/custom_graders.py:check_adr_quality' },
        {
          type: 'llm-rubric',
          value:
            'Grade the ADR quality in this architecture document (0-1):\n' +
            '1. Does each ADR have a clear Status?\n' +
            '2. Does each ADR have a Context section?\n' +
            '3. Does each ADR have a clear Decision statement?\n' +
            '4. Does each ADR document Consequences?\n' +
            '5. Are alternatives documented with neutral trade-offs?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },

    // ========================================
    // EXTENSION SYSTEM TESTS (3 tests)
    // ========================================

    // Test 19: Extension Manifest Validation
    {
      description: 'Extension: Manifest contains all required fields',
      prompt: 'file://../prompts/ext-prompt.txt',
      vars: {
        user_input:
          'Create a Spec Kit extension for Jira integration that syncs spec tasks to Jira issues, maps priority levels, and tracks issue status updates.',
      },
      assert: [
        { type: 'icontains', value: 'schema_version' },
        { type: 'icontains', value: 'extension' },
        { type: 'icontains', value: 'provides' },
        { type: 'icontains', value: 'commands' },
        { type: 'python', value: 'file://../graders/custom_graders.py:check_extension_manifest' },
      ],
    },

    // Test 20: Extension Skill Quality
    {
      description: 'Extension: Command is self-contained with no external references',
      prompt: 'file://../prompts/ext-prompt.txt',
      vars: {
        user_input:
          'Create a Spec Kit extension for automated code review that runs linting, checks test coverage, and generates a review summary report.',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_extension_self_containment' },
        {
          type: 'llm-rubric',
          value:
            'Grade the extension command quality (0-1):\n' +
            '1. Does the command have a clear Purpose section?\n' +
            '2. Does it list Prerequisites?\n' +
            '3. Does it have step-by-step execution instructions?\n' +
            '4. Does it include error handling guidance?\n' +
            '5. Is it self-contained (no @rule, @persona, @example references)?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },

    // Test 21: Extension Config Template
    {
      description: 'Extension: Config template has documented options and defaults',
      prompt: 'file://../prompts/ext-prompt.txt',
      vars: {
        user_input:
          'Create a Spec Kit extension for Slack notifications that posts spec status updates to channels, supports thread replies, and allows custom message templates.',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_extension_config' },
        {
          type: 'llm-rubric',
          value:
            'Grade the configuration template quality (0-1):\n' +
            '1. Are configuration options clearly documented with comments?\n' +
            '2. Are required vs optional fields marked?\n' +
            '3. Are sensible default values provided?\n' +
            '4. Is there guidance on environment variable overrides?\n' +
            '5. Is the YAML structure logical and well-organized?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },

    // ========================================
    // CLARIFY COMMAND TESTS (2 tests)
    // ========================================

    // Test 22: Clarify Identifies Gaps
    {
      description: 'Clarify: Identifies ambiguities in a vague specification',
      prompt: 'file://../prompts/clarify-prompt.txt',
      vars: {
        user_input:
          'Build a notification system. It should be fast and support multiple channels. Users should be able to configure their preferences. The system needs to handle high volumes.',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_clarification_quality' },
      ],
    },

    // Test 23: Architect Clarify Scope
    {
      description: 'Clarify: Focuses on architectural concerns for system-level spec',
      prompt: 'file://../prompts/clarify-prompt.txt',
      vars: {
        user_input:
          'We have an existing monolith handling 500 req/s. We want to add real-time features (live updates, presence indicators) and eventually support 50,000 concurrent users. The team has 3 backend developers. Current stack is Django + PostgreSQL.',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_architectural_focus' },
      ],
    },

    // ========================================
    // TRACE TEMPLATE TESTS (2 tests)
    // ========================================

    // Test 24: Trace Structure
    {
      description: 'Trace: Generated trace has all required sections',
      prompt: 'file://../prompts/trace-prompt.txt',
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
            '3. Does it include a decisions log with rationale?\n' +
            '4. Does it list quality gates (tests, coverage, security)?\n' +
            '5. Does it include artifacts produced?\n' +
            'Return average score 0-1.',
          threshold: 0.7,
        },
      ],
    },

    // Test 25: Trace Decision Quality
    {
      description: 'Trace: Decisions have proper rationale and alternatives',
      prompt: 'file://../prompts/trace-prompt.txt',
      vars: {
        user_input:
          'Create a session trace for building a real-time notification system. The team chose WebSockets over SSE for bidirectional communication, Redis pub/sub for message distribution, and PostgreSQL for persistence. Implementation faced challenges with connection scaling at 5000+ concurrent users.',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Grade the decision documentation quality (0-1):\n' +
            '1. Is each decision documented with context?\n' +
            '2. Are alternatives mentioned?\n' +
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
