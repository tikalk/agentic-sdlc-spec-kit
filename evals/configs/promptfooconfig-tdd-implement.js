// PromptFoo configuration for TDD Implement Context Detection tests
// Tests the /tdd.implement command's ability to detect context and run appropriate mode
module.exports = {
  description: 'TDD Implement Context Detection and In-Session Flow Evaluation',

  // Rate limiting to avoid 429 errors
  evaluateOptions: {
    maxConcurrency: 1,
    delay: process.env.CI ? 15000 : 5000,
  },

  // TDD Implement prompt
  prompts: ['file://../prompts/tdd-implement-prompt.txt'],

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
    // Test 1: Quick Mode Detection (No Spec Artifacts)
    {
      description: 'TDD: Detects Quick Mode when no spec artifacts exist',
      vars: {
        scenario: 'quick_mode_detection',
        context: 'Called from /quick.implement "Add JWT auth"',
        project_type: 'python_pytest',
        artifacts_present: false,
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_tdd_in_session_flow' },
        { type: 'icontains', value: 'Context Detection' },
        { type: 'icontains-any', value: ['Quick Mode', 'quick mode', 'in-session', 'In-Session'] },
        {
          type: 'llm-rubric',
          value:
            'Check Quick Mode detection:\n' +
            '1. Does output explicitly check for spec artifacts (increment-state.json, tasks.md)?\n' +
            '2. Does it declare "Quick Mode" or "in-session mode" when artifacts not found?\n' +
            '3. Does it NOT try to load files that do not exist?\n' +
            '4. Does it proceed to In-Session TDD Flow section?\n' +
            'Return 1.0 if all criteria met, 0.5 if partial, 0.0 if fails.',
          threshold: 0.8,
        },
      ],
    },

    // Test 2: Spec Mode Detection (With Artifacts)
    {
      description: 'TDD: Detects Spec Mode when artifacts exist',
      vars: {
        scenario: 'spec_mode_detection',
        context: 'Running in specs/feature-001/ with existing increment-state.json',
        project_type: 'python_pytest',
        artifacts_present: true,
        current_increment: 2,
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_tdd_in_session_flow' },
        { type: 'icontains', value: 'Context Detection' },
        { type: 'icontains-any', value: ['Spec Mode', 'spec mode', 'file-based'] },
        { type: 'icontains', value: 'increment-state.json' },
        {
          type: 'llm-rubric',
          value:
            'Check Spec Mode detection:\n' +
            '1. Does output find and mention existing artifacts?\n' +
            '2. Does it declare "Spec Mode" or "file-based mode"?\n' +
            '3. Does it load state from increment-state.json?\n' +
            '4. Does it resume from the correct increment (not start fresh)?\n' +
            'Return 1.0 if all criteria met, 0.5 if partial, 0.0 if fails.',
          threshold: 0.8,
        },
      ],
    },

    // Test 3: Language Detection in Quick Mode
    {
      description: 'TDD: Runs language detection in Quick Mode',
      vars: {
        scenario: 'quick_language_detection',
        context: 'Called from /quick.implement',
        project_type: 'typescript_vitest',
        artifacts_present: false,
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_tdd_in_session_flow' },
        { type: 'icontains', value: 'Language Detection' },
        { type: 'icontains', value: 'detect-language' },
        {
          type: 'llm-rubric',
          value:
            'Check language detection in Quick Mode:\n' +
            '1. Does it run the detect-language script?\n' +
            '2. Does it detect the correct language (TypeScript) and framework (vitest)?\n' +
            '3. Does it capture results in-session (not require file persistence)?\n' +
            '4. Are test commands appropriate for detected language?\n' +
            'Return 1.0 if all criteria met, 0.5 if partial, 0.0 if fails.',
          threshold: 0.7,
        },
      ],
    },

    // Test 4: Condensed Planning Questions in Quick Mode
    {
      description: 'TDD: Asks condensed planning questions in Quick Mode',
      vars: {
        scenario: 'quick_planning_questions',
        context: 'Called from /quick.implement "Add payment processing"',
        project_type: 'python_pytest',
        artifacts_present: false,
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_tdd_in_session_flow' },
        { type: 'icontains', value: 'Planning' },
        {
          type: 'llm-rubric',
          value:
            'Check condensed planning in Quick Mode:\n' +
            '1. Does it ask about public interfaces being added/modified?\n' +
            '2. Does it ask about key behaviors to test?\n' +
            '3. Does it ask about testability concerns?\n' +
            '4. Are there 3 questions (not 5, which is the full tdd.plan)?\n' +
            'Return 1.0 if all 3 questions present, 0.67 if 2, 0.33 if 1, 0.0 if none.',
          threshold: 0.7,
        },
      ],
    },

    // Test 5: Increment Generation in Quick Mode
    {
      description: 'TDD: Generates proper test increments in Quick Mode',
      vars: {
        scenario: 'quick_increment_generation',
        context: 'Called from /quick.implement "Add user registration"',
        project_type: 'python_pytest',
        artifacts_present: false,
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_tdd_in_session_flow' },
        { type: 'icontains', value: 'TDD-001' },
        { type: 'icontains-any', value: ['Degenerate', 'degenerate'] },
        { type: 'icontains-any', value: ['Happy Path', 'happy path'] },
        { type: 'icontains-any', value: ['Edge Cases', 'edge'] },
        {
          type: 'llm-rubric',
          value:
            'Check increment generation in Quick Mode:\n' +
            '1. Are increments named TDD-001, TDD-002, etc.?\n' +
            '2. Are there categories (Degenerate, Happy, Edge, Error)?\n' +
            '3. Is happy path marked with [P] for priority?\n' +
            '4. Are there at least 4-6 increments generated?\n' +
            '5. Are descriptions clear and testable?\n' +
            'Return 1.0 if all criteria met, proportional for partial.',
          threshold: 0.7,
        },
      ],
    },

    // Test 6: RED→GREEN→REFACTOR Phases Present
    {
      description: 'TDD: All three RED/GREEN/REFACTOR phases present',
      vars: {
        scenario: 'red_green_refactor',
        context: 'In Quick Mode processing increments',
        project_type: 'go_testing',
        artifacts_present: false,
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_tdd_in_session_flow' },
        { type: 'icontains-any', value: ['RED', 'Red', '🔴'] },
        { type: 'icontains-any', value: ['GREEN', 'Green', '🟢'] },
        { type: 'icontains-any', value: ['REFACTOR', 'Refactor', '🔵'] },
        {
          type: 'llm-rubric',
          value:
            'Check RED→GREEN→REFACTOR phases:\n' +
            '1. Is RED phase present (write failing test)?\n' +
            '2. Is GREEN phase present (minimal implementation)?\n' +
            '3. Is REFACTOR phase present (improvements while tests pass)?\n' +
            '4. Are phases executed for each increment?\n' +
            'Return 1.0 if all phases present, 0.67 if 2, 0.33 if 1, 0.0 if none.',
          threshold: 0.7,
        },
      ],
    },

    // Test 7: No File Persistence in Quick Mode
    {
      description: 'TDD: Does NOT create files in Quick Mode',
      vars: {
        scenario: 'quick_no_files',
        context: 'Called from /quick.implement',
        project_type: 'python_pytest',
        artifacts_present: false,
      },
      assert: [
        {
          type: 'llm-rubric',
          value:
            'Check no file persistence in Quick Mode:\n' +
            '1. Does it NOT mention writing increment-state.json?\n' +
            '2. Does it NOT mention writing language-detected.json?\n' +
            '3. Does it NOT mention writing tasks.md?\n' +
            '4. Does it note that state is session-only (tracked in conversation)?\n' +
            'Return 1.0 if no file persistence, 0.5 if ambiguous, 0.0 if creates files.',
          threshold: 0.8,
        },
      ],
    },

    // Test 8: State Saving in Spec Mode
    {
      description: 'TDD: Saves state to file in Spec Mode',
      vars: {
        scenario: 'spec_state_save',
        context: 'Running in specs/feature-001/ with existing state',
        project_type: 'python_pytest',
        artifacts_present: true,
        current_increment: 3,
      },
      assert: [
        { type: 'python', value: 'file://../graders/custom_graders.py:check_tdd_in_session_flow' },
        { type: 'icontains', value: 'Save State' },
        { type: 'icontains', value: 'increment-state.json' },
        {
          type: 'llm-rubric',
          value:
            'Check state saving in Spec Mode:\n' +
            '1. Does it mention saving state to increment-state.json?\n' +
            '2. Does it update the current increment after completion?\n' +
            '3. Is this done ONLY in spec mode (not quick mode)?\n' +
            'Return 1.0 if proper file persistence, 0.0 if not saving state.',
          threshold: 0.7,
        },
      ],
    },
  ],
};
