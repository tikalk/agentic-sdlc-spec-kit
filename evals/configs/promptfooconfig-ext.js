// PromptFoo configuration for Extension System tests
module.exports = {
  description: 'Extension System Quality Evaluation',

  // Rate limiting to avoid 429 errors
  concurrency: 1,
  delay: process.env.CI ? 15000 : 2000, // 15s in CI to avoid rate limiting, 2s locally

  // Extension prompt
  prompts: ['file://../prompts/ext-prompt.txt'],

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
    // Test 1: Extension Manifest Validation
    {
      description: 'Extension: Manifest contains all required fields',
      vars: {
        user_input:
          'Create a Spec Kit extension for Jira integration that syncs spec tasks to Jira issues, maps priority levels, and tracks issue status updates.',
      },
      assert: [
        { type: 'icontains', value: 'schema_version' },
        { type: 'icontains', value: 'extension' },
        { type: 'icontains', value: 'provides' },
        { type: 'icontains', value: 'commands' },
        {
          type: 'python',
          value: 'file://../graders/custom_graders.py:check_extension_manifest',
        },
      ],
    },

    // Test 2: Extension Skill Quality (self-containment)
    {
      description: 'Extension: Command is self-contained with no external references',
      vars: {
        user_input:
          'Create a Spec Kit extension for automated code review that runs linting, checks test coverage, and generates a review summary report.',
      },
      assert: [
        {
          type: 'python',
          value: 'file://../graders/custom_graders.py:check_extension_self_containment',
        },
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

    // Test 3: Extension Config Template Quality
    {
      description: 'Extension: Config template has documented options and defaults',
      vars: {
        user_input:
          'Create a Spec Kit extension for Slack notifications that posts spec status updates to channels, supports thread replies, and allows custom message templates.',
      },
      assert: [
        {
          type: 'python',
          value: 'file://../graders/custom_graders.py:check_extension_config',
        },
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
  ],
};
