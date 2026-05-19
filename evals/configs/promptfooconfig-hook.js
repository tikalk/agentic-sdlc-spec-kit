module.exports = {
  description: 'Hook execution behavior eval - detect deadlock regression',
  defaultTest: {
    assert: [
      {
        type: 'python',
        value: 'file://../graders/custom_graders.py:check_pii_leakage'
      },
      {
        type: 'python',
        value: 'file://../graders/custom_graders.py:check_prompt_injection'
      },
      {
        type: 'python',
        value: 'file://../graders/custom_graders.py:check_hallucination_signals'
      },
      {
        type: 'python',
        value: 'file://../graders/custom_graders.py:check_misinformation'
      }
    ]
  },
  providers: [
    {
      id: 'openai:gpt-4.1'
    },
    {
      id: 'anthropic:claude-sonnet-4-20250514'
    },
    {
      id: 'google:gemini-2.5-pro-preview-0605'
    }
  ],
  prompts: [
    [
      {
        role: 'system',
        content: 'file://../prompts/hook-prompt.txt'
      }
    ]
  ],
  tests: [
    {
      description: 'Hook deadlock: mandatory pre-hook does not block workflow',
      vars: {
        user_input: 'Update the project constitution with these principles:\n- Principle 1: Test-first development\n- Principle 2: Incremental progress\n- Principle 3: Evidence-based decisions'
      },
      assert: [
        {
          type: 'not-icontains',
          value: 'EXECUTE_COMMAND'
        },
        {
          type: 'not-icontains',
          value: 'Wait for the result of the hook'
        },
        {
          type: 'not-icontains',
          value: 'waiting for'
        },
        {
          type: 'python',
          value: 'file://../graders/custom_graders.py:check_hook_execution_flow'
        }
      ]
    },
    {
      description: 'Hook deadlock: optional hook offers choice, main workflow still runs',
      vars: {
        user_input: 'Add a new principle about security to the constitution.'
      },
      assert: [
        {
          type: 'not-icontains',
          value: 'EXECUTE_COMMAND'
        },
        {
          type: 'contains',
          value: 'Outline'
        },
        {
          type: 'python',
          value: 'file://../graders/custom_graders.py:check_hook_execution_flow'
        }
      ]
    },
    {
      description: 'Hook deadlock: no extensions - clean execution',
      vars: {
        user_input: 'Create an initial constitution for a new project.'
      },
      assert: [
        {
          type: 'not-icontains',
          value: 'Extension Hooks'
        },
        {
          type: 'contains',
          value: 'constitution'
        },
        {
          type: 'contains',
          value: 'version'
        }
      ]
    }
  ]
};