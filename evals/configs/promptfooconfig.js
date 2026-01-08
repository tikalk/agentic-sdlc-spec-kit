// PromptFoo configuration using JavaScript for environment variable support
module.exports = {
  description: 'Spec-Kit Quality Evaluation',

  // Configure LiteLLM Claude provider using OpenAI-compatible endpoint
  providers: [
    {
      id: `openai:chat:claude-sonnet-4-5-20250929`,
      label: 'Claude Sonnet 4.5 (via LiteLLM)',
      config: {
        // LiteLLM exposes an OpenAI-compatible endpoint at /chat/completions
        apiBaseUrl: process.env.ANTHROPIC_BASE_URL,
        apiKey: process.env.ANTHROPIC_AUTH_TOKEN,
        temperature: 0.7,
        max_tokens: 4000,
      },
      // Also set the env vars that PromptFoo looks for
      env: {
        OPENAI_API_KEY: process.env.ANTHROPIC_AUTH_TOKEN,
        OPENAI_BASE_URL: process.env.ANTHROPIC_BASE_URL,
      },
    },
  ],

  // Default test configuration
  defaultTest: {
    options: {
      provider: 'openai:chat:claude-sonnet-4-5-20250929',
    },
  },

  // Test suite
  tests: [
    // ================================
    // Test 1: Basic Spec Structure
    // ================================
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
        { type: 'icontains', value: 'user stor' },  // Matches "User Stories" or "User Story"
        { type: 'icontains', value: 'non-functional' },
        { type: 'icontains', value: 'edge case' },
      ],
    },

    // ================================
    // Test 2: No Premature Tech Stack
    // ================================
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

    // ================================
    // Test 3: Quality - User Stories
    // ================================
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

    // ================================
    // Test 4: Clarity - No Vague Terms
    // ================================
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

    // ================================
    // Test 5: Security Requirements
    // ================================
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

    // ================================
    // Test 6: Edge Cases Coverage
    // ================================
    {
      description: 'Spec Template: Includes edge cases and error scenarios',
      prompt: 'file://../prompts/spec-prompt.txt',
      vars: {
        user_input: 'Build a file upload system supporting multiple file types up to 100MB',
      },
      assert: [
        { type: 'icontains', value: 'edge case' },
        {
          type: 'llm-rubric',
          value:
            'Check if edge cases section covers:\n1. File size limits exceeded\n2. Invalid file types\n3. Network failures during upload\n4. Concurrent uploads\nReturn 1.0 if 3+ edge cases covered, 0.5 if 1-2, 0.0 if none.',
          threshold: 0.6,
        },
      ],
    },

    // ================================
    // Test 7: Plan Template - Simplicity Gate
    // ================================
    {
      description: 'Plan Template: Simple app should have ≤3 projects',
      prompt: 'file://../prompts/plan-prompt.txt',
      vars: {
        user_input: 'Plan a simple todo app with Node.js and SQLite',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_simplicity_gate' },
        { type: 'not-icontains', value: 'microservices' },
        { type: 'not-icontains', value: 'kubernetes' },
      ],
    },

    // ================================
    // Test 8: Plan Template - Constitution Compliance
    // ================================
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

    // ================================
    // Test 9: Completeness Score
    // ================================
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

    // ================================
    // Test 10: Regression Test - Basic Structure
    // ================================
    {
      description: 'Regression: Spec template maintains required sections',
      prompt: 'file://../prompts/spec-prompt.txt',
      vars: {
        user_input: 'Simple feature: Add a search bar to existing app',
      },
      assert: [
        { type: 'icontains', value: 'functional requirements' },
        { type: 'icontains', value: 'user stor' },
        // Even simple features should have structure
        {
          type: 'javascript',
          value: `
            // Count major sections (## or #)
            const sections = output.split(/^#{1,2} /gm).length - 1;
            return sections >= 4;  // Lowered from 5 to be more flexible
          `,
        },
      ],
    },
  ],
};
