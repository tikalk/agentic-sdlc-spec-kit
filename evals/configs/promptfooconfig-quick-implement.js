// PromptFoo configuration for Quick Implement with Hook Support tests
// Tests the /quick.implement command's hook discovery and execution
module.exports = {
  description: 'Quick Implement Hook Support Evaluation',

  // Rate limiting to avoid 429 errors
  evaluateOptions: {
    maxConcurrency: 1,
    delay: process.env.CI ? 15000 : 5000,
  },

  // Quick Implement prompt
  prompts: ['file://../prompts/quick-implement-prompt.txt'],

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
    // Test 1: Mandatory before_implement hook execution
    {
      description: 'Quick: Executes mandatory before_implement hook before tasks',
      vars: {
        scenario: 'mandatory_before_hook',
        user_input: 'Add user authentication to the API',
        mission_brief_q1: 'Add JWT-based authentication',
        mission_brief_q2: 'API returns 401 for unauthenticated requests',
        mission_brief_q3: 'Use existing user model',
        approval: 'yes',
        context: 'Look at src/api/users.py',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_quick_implement_hooks' },
        { type: 'icontains', value: 'Extension Hooks' },
        { type: 'icontains', value: 'before_implement' },
        { type: 'icontains', value: 'tdd.implement' },
        {
          type: 'llm-rubric',
          value:
            'Check if the mandatory before_implement hook is executed correctly:\n' +
            '1. Does the output mention checking .specify/extensions.yml?\n' +
            '2. Is the mandatory hook (tdd.implement) executed BEFORE task execution?\n' +
            '3. Does it NOT ask for user confirmation on the mandatory hook?\n' +
            '4. Does the workflow proceed to task execution after the hook?\n' +
            'Return 1.0 if all criteria met, 0.5 if some, 0.0 if critical failure.',
          threshold: 0.7,
        },
      ],
    },

    // Test 2: Optional after_implement hook display
    {
      description: 'Quick: Displays optional after_implement hook after tasks',
      vars: {
        scenario: 'optional_after_hook',
        user_input: 'Fix authentication bug in login flow',
        mission_brief_q1: 'Fix login redirect issue',
        mission_brief_q2: 'Login redirects to dashboard after successful auth',
        mission_brief_q3: 'Must work with existing session token',
        approval: 'yes',
        context: 'Check the login component',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_quick_implement_hooks' },
        { type: 'icontains', value: 'after_implement' },
        { type: 'icontains', value: 'tdd.validate' },
        { type: 'icontains', value: 'optional' },
        {
          type: 'llm-rubric',
          value:
            'Check if the optional after_implement hook is displayed correctly:\n' +
            '1. Does the output check hooks.after_implement?\n' +
            '2. Is the optional hook (tdd.validate) shown AFTER task completion?\n' +
            '3. Is it clearly marked as optional (not mandatory)?\n' +
            '4. Is there a clear prompt to execute the optional hook?\n' +
            'Return 1.0 if all criteria met, 0.5 if some, 0.0 if missing.',
          threshold: 0.7,
        },
      ],
    },

    // Test 3: Hook deadlock prevention
    {
      description: 'Quick: No hook deadlock - executes without waiting indefinitely',
      vars: {
        scenario: 'deadlock_prevention',
        user_input: 'Add dark mode toggle',
        mission_brief_q1: 'Add dark mode toggle to settings',
        mission_brief_q2: 'Button toggles theme, persists preference',
        mission_brief_q3: 'Use existing theme system',
        approval: 'yes',
        context: 'Check settings component',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_hook_execution_flow' },
        {
          type: 'llm-rubric',
          value:
            'Check for hook execution deadlock prevention:\n' +
            '1. Does the hook execute immediately (not suggest running later)?\n' +
            '2. Is there no "EXECUTE_COMMAND" + "wait for result" pattern?\n' +
            '3. Does the workflow complete (mission brief → tasks → summary)?\n' +
            '4. Is there no indefinite waiting for user input after hooks?\n' +
            'Return 1.0 if no deadlock patterns, 0.0 if deadlocking behavior present.',
          threshold: 0.8,
        },
      ],
    },

    // Test 4: No extensions.yml - silent skip
    {
      description: 'Quick: Skips hooks silently when extensions.yml missing',
      vars: {
        scenario: 'no_extensions_file',
        user_input: 'Update README with installation instructions',
        mission_brief_q1: 'Add installation section to README',
        mission_brief_q2: 'Clear setup instructions for new developers',
        mission_brief_q3: 'None',
        approval: 'yes',
        context: 'None needed',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Check silent skip when no extensions.yml:\n' +
            '1. Does the workflow proceed normally without errors?\n' +
            '2. Is there no mention of missing file errors?\n' +
            '3. Does it complete Mission Brief → Tasks → Execution → Summary?\n' +
            '4. Is the output clean (no hook-related warnings)?\n' +
            'Return 1.0 if silent skip, 0.5 if mentions but continues, 0.0 if fails.',
          threshold: 0.7,
        },
      ],
    },

    // Test 5: Both hooks present - correct ordering
    {
      description: 'Quick: Executes before_implement, tasks, then after_implement in order',
      vars: {
        scenario: 'both_hooks_ordering',
        user_input: 'Refactor database connection handling',
        mission_brief_q1: 'Refactor DB connection to use connection pooling',
        mission_brief_q2: 'All existing queries work, improved performance',
        mission_brief_q3: 'Must maintain backward compatibility',
        approval: 'yes',
        context: 'Check database module',
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_quick_implement_hooks' },
        {
          type: 'llm-rubric',
          value:
            'Check correct hook ordering:\n' +
            '1. Is before_implement hook executed BEFORE task execution?\n' +
            '2. Are quick tasks executed AFTER before_implement hook?\n' +
            '3. Is after_implement hook shown AFTER task completion?\n' +
            '4. Is the order: before_hook → tasks → after_hook?\n' +
            'Return 1.0 if correct order, 0.5 if partially correct, 0.0 if wrong order.',
          threshold: 0.8,
        },
      ],
    },

    // Test 6: Hook with enabled: false filtering
    {
      description: 'Quick: Filters out hooks with enabled: false',
      vars: {
        scenario: 'disabled_hook_filtering',
        user_input: 'Add logging to API endpoints',
        mission_brief_q1: 'Add structured logging to all API endpoints',
        mission_brief_q2: 'Logs include request/response data and timing',
        mission_brief_q3: 'Use existing logging configuration',
        approval: 'yes',
        context: 'Check middleware setup',
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Check hook filtering with enabled: false:\n' +
            '1. Does the output mention filtering or checking enabled status?\n' +
            '2. Are disabled hooks NOT executed?\n' +
            '3. Do enabled hooks still execute normally?\n' +
            '4. Is the workflow correct despite mixed enabled/disabled hooks?\n' +
            'Return 1.0 if proper filtering, 0.5 if unclear, 0.0 if disabled hooks run.',
          threshold: 0.6,
        },
      ],
    },

    // Test 7: Workflow completion with hooks
    {
      description: 'Quick: Completes full workflow even with hook execution',
      vars: {
        scenario: 'workflow_completion',
        user_input: 'Implement rate limiting',
        mission_brief_q1: 'Add rate limiting to API endpoints',
        mission_brief_q2: 'Limit is 100 requests per minute per user',
        mission_brief_q3: 'Return 429 status when limit exceeded',
        approval: 'yes',
        context: 'Check API middleware',
      },
      assert: [
        { type: 'icontains', value: 'Mission Brief' },
        { type: 'icontains', value: 'Task Breakdown' },
        { type: 'icontains', value: 'Quick Implementation Complete' },
        { type: 'icontains', value: 'after_task_execute' },
        {
          type: 'llm-rubric',
          value:
            'Check full workflow completion with hooks:\n' +
            '1. Does Mission Brief phase complete (questions + approval)?\n' +
            '2. Is Task Breakdown generated?\n' +
            '3. Are before/after hooks handled?\n' +
            '4. Are per-task hooks (before_task_execute/after_task_execute) dispatched?\n' +
            '5. Is Summary shown at the end?\n' +
            'Return 1.0 if all phases complete, proportional for partial.',
          threshold: 0.8,
        },
      ],
    },
  ],
};
